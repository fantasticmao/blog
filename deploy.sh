#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Remove the publish directory
# rm -rf ./docs/

# Build the project.
# hugo

# Add changes to git.
git add .

# Commit changes.
msg="Site updated: $(date +'%Y-%m-%d %H:%M:%S')"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master