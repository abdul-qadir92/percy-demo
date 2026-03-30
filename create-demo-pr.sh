#!/bin/bash

set -e

if ! [ -x "$(command -v hub)" ]; then
  echo 'Error: hub is not installed (https://hub.github.com/). Please run "brew install hub".' >&2
  exit 1
fi

NOW=`date +%d%H%M%S`
BASE_BRANCH="main-$NOW"
BRANCH="update-button-$NOW"

# FIX 1: Quote the variable to prevent syntax errors when it is empty
if [ "$CI_USER_ID" != "" ]
then
  BASE_BRANCH=${CI_USER_ID}_${BASE_BRANCH}
  BRANCH=${CI_USER_ID}_${BRANCH}
fi

# cd to current directory as root of script
cd "$(dirname "$0")"

# Create a "main-123123" branch for the PR's baseline.
# This allows demo PRs to be merged without fear of breaking the actual main.
git checkout main
git checkout -b $BASE_BRANCH
git push origin $BASE_BRANCH

# Create the update-button-123123 PR. It is always a fork of the update-button-base branch.
git checkout update-button-base
git checkout -b $BRANCH
git commit --amend -m 'Change Sign Up button style.'
git push origin $BRANCH

# FIX 2: Use awk to grab ONLY the text after the final slash in the URL to avoid grabbing the "92" in your username
PR_NUM=$(hub pull-request -b $BASE_BRANCH -m 'Change Sign Up button style.' | awk -F/ '{print $NF}')

export PERCY_BRANCH=$BRANCH
export PERCY_PULL_REQUEST=$PR_NUM

npm test

# FIX 3: Change the hardcoded repository from browserstack to your actual repository
# Uses a personal access token (https://github.com/settings/tokens) which has scope "repo:status".
curl \
  -u "$GITHUB_USER:$GITHUB_TOKEN" \
  -d '{"state": "success", "target_url": "https://example.com/build/status", "description": "Tests passed", "context": "ci/service"}' \
  "https://api.github.com/repos/abdul-qadir92/percy-demo/statuses/$(git rev-parse --verify HEAD)"

git checkout main
git branch -D $BASE_BRANCH
git branch -D $BRANCH
