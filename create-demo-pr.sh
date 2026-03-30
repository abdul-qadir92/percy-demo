#!/bin/bash
set -e

# Use gh (GitHub CLI) instead of hub
if ! [ -x "$(command -v gh)" ]; then
  echo 'Error: gh cli is not installed.' >&2
  exit 1
fi

# 1. Setup Identity & Auth
# Force-login the CLI using the token passed from Azure
echo "$GITHUB_TOKEN" | gh auth login --with-token

# Dynamically find the repo name (e.g., abdul-qadir92/percy-demo)
# This prevents 404/401 errors if the script thinks it's still BrowserStack
REPO_NAME=$(git config --get remote.origin.url | sed 's/.*github.com[\/:]//;s/\.git$//')
echo "Targeting Repository: $REPO_NAME"

# Update remote URL to use the token for git pushes
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO_NAME}.git"
git remote set-url origin "$REPO_URL"

NOW=`date +%d%H%M%S`
USER_PREFIX=${CI_USER_ID:-"demo"}
BASE_BRANCH="${USER_PREFIX}_main-$NOW"
BRANCH="${USER_PREFIX}_update-button-$NOW"

# 2. Create the temporary Baseline branch
git checkout main
git checkout -b $BASE_BRANCH
git push origin $BASE_BRANCH

# 3. Create the "Visual Change" branch
git checkout update-button-base
git checkout -b $BRANCH
# --allow-empty prevents the script from crashing if no changes were detected
git commit --allow-empty -m 'Change Sign Up button style.'
git push origin $BRANCH

# 4. Open the Pull Request
echo "Creating Pull Request..."
# We add --repo to be 100% explicit
PR_URL=$(gh pr create \
  --repo "$REPO_NAME" \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "Percy Visual Demo ($NOW)" \
  --body "Automated PR for visual testing.")

# Extract PR Number safely from the URL
PR_NUM=$(echo $PR_URL | grep -oE '[0-9]+$')
echo "PR Created Successfully: #$PR_NUM"

# 5. Export Percy Variables
# These MUST be exported before npm test
export PERCY_BRANCH=$BRANCH
export PERCY_PULL_REQUEST=$PR_NUM
export PERCY_TOKEN=$PERCY_TOKEN

# 6. Run Percy
# This usually runs 'percy exec -- npm test' under the hood
npm test

# 7. Mark PR as 'Tests Passed'
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REPO_NAME}/statuses/$(git rev-parse --verify HEAD)" \
  -d "{\"state\":\"success\",\"target_url\":\"https://visual.percy.io\",\"description\":\"Percy snapshots captured!\",\"context\":\"ci/percy\"}"

# Cleanup
git checkout main
