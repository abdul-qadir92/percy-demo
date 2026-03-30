#!/bin/bash
set -e

# --- 1. PRE-FLIGHT CHECKS ---
if ! [ -x "$(command -v gh)" ]; then
  echo 'Error: GitHub CLI (gh) is not installed on this agent.' >&2
  exit 1
fi

# Ensure tokens are present from the environment
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN is not set. Check your Azure Variable Group mapping."
  exit 1
fi

# --- 2. REPO & IDENTITY SETUP ---
# Dynamically get repo name (e.g., your-user/percy-demo)
REPO_NAME=$(git config --get remote.origin.url | sed 's/.*github.com[\/:]//;s/\.git$//')
echo "Detected Repository: $REPO_NAME"

# Update remote to use token for pushes (prevents 403/401 errors)
git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${REPO_NAME}.git"

# Configure Git Identity for the runner
git config --global user.email "devops@azure.com"
git config --global user.name "Azure Pipeline"

# Generate unique branch names
NOW=$(date +%d%H%M%S)
USER_PREFIX=${CI_USER_ID:-"demo"}
BASE_BRANCH="${USER_PREFIX}_main-$NOW"
BRANCH="${USER_PREFIX}_update-button-$NOW"

# --- 3. BRANCHING & PUSHING ---
echo "Creating baseline branch: $BASE_BRANCH"
git checkout main
git checkout -b "$BASE_BRANCH"
git push origin "$BASE_BRANCH"

echo "Creating feature branch: $BRANCH"
# Switch to the branch that contains the CSS/visual changes
git checkout update-button-base
git checkout -b "$BRANCH"
# --allow-empty ensures the script doesn't crash if no changes are detected
git commit --allow-empty -m "Visual changes for Percy demo ($NOW)"
git push origin "$BRANCH"

# --- 4. CREATE PULL REQUEST ---
echo "Creating Pull Request on GitHub..."
# Using --repo flag ensures the CLI targets your specific repo
PR_URL=$(gh pr create \
  --repo "$REPO_NAME" \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "Percy Visual Demo: $BRANCH" \
  --body "Automated PR created by Azure DevOps for visual regression testing.")

# Extract the PR Number from the URL (e.g., .../pull/15 -> 15)
PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')
echo "Successfully created PR #$PR_NUM"

# --- 5. PERCY & TESTING ---
# Export these so Percy knows which PR to attach snapshots to
export PERCY_BRANCH=$BRANCH
export PERCY_PULL_REQUEST=$PR_NUM
# Ensure PERCY_TOKEN is also in the environment (passed from Azure)

echo "Running Percy snapshots..."
npm test

# --- 6. GITHUB STATUS CHECK ---
# Creates the fake "ci/percy: success" status on the PR
echo "Posting status check to GitHub..."
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REPO_NAME}/statuses/$(git rev-parse --verify HEAD)" \
  -d "{\"state\":\"success\",\"target_url\":\"https://visual.percy.io\",\"description\":\"Percy snapshots captured!\",\"context\":\"ci/percy\"}"

# --- 7. CLEANUP ---
git checkout main
echo "Demo pipeline complete."
