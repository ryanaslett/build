###
# node-test-commit-pre
# All actions run before pending post-build-status-update job is run
###

# Git
git --version

# Name and email in git config need to be the same across all jobs
# so that git rebase --committer-date-is-author-date will produce
# the same commit SHA1
git config --replace-all user.name Dummy
git config --replace-all user.email dummy@dummy.com
git config user.name
git config user.email
echo $GIT_COMMITTER_NAME
echo $GIT_AUTHOR_NAME

git rebase --abort || true
git checkout -f refs/remotes/origin/_jenkins_local_branch
git config user.name
git config user.email
echo $GIT_COMMITTER_NAME
echo $GIT_AUTHOR_NAME

git status
git rev-parse HEAD
git rev-parse $REBASE_ONTO

# COMMIT_SHA_CHECK must be specified, unless the
# org/repo is nodejs/node and the ref is not a GitHub pull request
if [ -z "${COMMIT_SHA_CHECK}" ]; then
  if [ "${GITHUB_ORG}" != "nodejs" ] || [ "${REPO_NAME}" != "node" ] || echo "${GIT_REMOTE_REF}" | grep -qE '^(refs/)?pull/[0-9]+'; then
    echo "Error: Starting CI for ${GIT_REMOTE_REF} from ${GITHUB_ORG}/${REPO_NAME} is not allowed without a specified COMMIT_SHA_CHECK value"
    exit 1
  fi
  echo "Allowing ${GIT_REMOTE_REF} for ${GITHUB_ORG}/${REPO_NAME} without a specified COMMIT_SHA_CHECK"
else
  # Check COMMIT_SHA_CHECK looks like a SHA and not some other git ref
  # (e.g. branch ref)
  if ! echo "${COMMIT_SHA_CHECK}" | grep -qE '^[0-9a-fA-F]+$'; then
    echo "Error: COMMIT_SHA_CHECK does not look like a SHA"
    exit 1
  fi

  # Check that the git ref that is checked out hasn't been updated since
  # the job was requested.
  if [ "$(git rev-parse HEAD)" != "$(git rev-parse ${COMMIT_SHA_CHECK})" ]; then
    echo "Error: HEAD does not match expected COMMIT_SHA_CHECK"
    exit 1
  fi
fi

if [ -n "${REBASE_ONTO}" ]; then
  git rebase --committer-date-is-author-date $REBASE_ONTO
fi

if [ -n "${POST_REBASE_SHA1_CHECK}" ]; then
  check_sha1=${POST_REBASE_SHA1_CHECK}
  head_sha1=$(git rev-parse HEAD)
  if [ "$head_sha1" != "$check_sha1" ]; then
    exit 1
  fi
fi

# Run the local copy, if we have one, or fetch the latest from GitHub.
LOCAL_SCRIPT="${WORKSPACE}/build/jenkins/scripts/node-test-commit-diagnostics.sh"
if [ -e "${LOCAL_SCRIPT}" ]; then
  bash -ex "${LOCAL_SCRIPT}" before
else
  curl https://raw.githubusercontent.com/nodejs/build/main/jenkins/scripts/node-test-commit-diagnostics.sh | bash -ex -s before
fi
