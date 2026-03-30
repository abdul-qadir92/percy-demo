#!/bin/bash
set -e

# Use gh (GitHub CLI) instead of hub
if ! [ -x "$(command -v gh)" ]; then
  echo 'Error: gh cli is not installed.' >&2
  exit 1
fi

# 1. Setup Identity & Auth
# We use the GITHUB_TOKEN to authenticate git pushes automatically
REPO_URL=$(git config --get remote.origin.url | sed "s/https:\/\//https:\/\/x-access-token:${GITHUB_TOKEN}@/")
git remote set-url origin "$REPO_URL"

NOW=`date +%d%H%M%S`
USER_PREFIX=${CI_USER_ID:-"demo"}
BASE_BRANCH="${USER_PREFIX}_main-$NOW"
BRANCH="${USER_PREFIX}_update-button-$NOW"

# 2. Create the temporary Baseline branch for comparison
git checkout main
git checkout -b $BASE_BRANCH
git push origin $BASE_BRANCH

# 3. Create the "Visual Change" branch
# This assumes the pipeline already modified files on 'update-button-base'
git checkout update-button-base
git checkout -b $BRANCH
git commit --amend --no-edit # Solidify the changes made by the pipeline
git push origin $BRANCH

# 4. Open the Pull Request
echo "Creating Pull Request..."
PR_URL=$(gh pr create --base $BASE_BRANCH --head $BRANCH --title "Percy Visual Demo ($NOW)" --body "Automated PR for visual testing.")
PR_NUM=$(echo $PR_URL | grep -oE '[0-9]+$')

export PERCY_BRANCH=$BRANCH
export PERCY_PULL_REQUEST=$PR_NUM

# 5. Run Percy
npm test

# 6. Mark PR as 'Tests Passed' (Optional status check)
REPO_NAME=$(git config --get remote.origin.url | sed 's/.*github.com[\/:]//;s/\.git$//')
curl -H "Authorization: token $GITHUB_TOKEN" \
  -d '{"state": "success", "target_url": "https://visual.percy.io", "description": "Visuals captured", "context": "ci/percy"}' \
  "https://api.github.com/repos/${REPO_NAME}/statuses/$(git rev-parse --verify HEAD)"

# Cleanup local tracking
git checkout main