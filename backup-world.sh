#!/usr/bin/env bash
# This script periodically commits the world file to the git repository.
# It's a safety measure for ephemeral environments like Codespaces.

cd "$(dirname "$0")" || exit

# Make sure we have a world name to work with from the server config.
world_file_path=$(grep '^world=' serverconfig.txt | cut -d'=' -f2 | tr -d '\r')

if [ -z "$world_file_path" ]; then
    echo "Could not find 'world=' entry in serverconfig.txt"
    echo "Please specify a world file to enable backups."
    exit 1
fi

echo "Will backup world file: $world_file_path"

# We need to set a git user for commits.
git config --global user.name "Codespaces Backup Bot"
git config --global user.email "codespaces-backup-bot@users.noreply.github.com"

echo "Starting world backup process..."

while true; do
  # Wait for 10 minutes. The server's default autosave is 10 minutes.
  # We'll wait slightly longer to increase the chance of backing up a fresh save.
  sleep 900

  echo "Backing up world file..."
  git pull # Ensure we have the latest changes from remote before pushing

  # Add both the main world and its primary backup.
  git add "$world_file_path" "$world_file_path.bak"

  # Check if there are any changes to the world file to commit.
  if git diff-index --quiet HEAD --; then
    echo "No changes to world file detected. Skipping backup."
  else
    timestamp=$(date)
    echo "Changes detected. Committing and pushing world save from $timestamp"
    git commit -m "Automated world backup: $timestamp"
    git push
  fi
done
