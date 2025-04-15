#!/bin/bash
set -e

ACTIVE_FILE="config/active_level.txt"

# Check if active level file exists
if [ ! -f "$ACTIVE_FILE" ]; then
  echo "❌ No active level found. Nothing to destroy."
  exit 1
fi

LEVEL=$(cat "$ACTIVE_FILE")

# Confirm with user
read -p "🔥 Destroy the running instance of $LEVEL using Terraform? [y/N]: " confirm
if [[ ! $confirm =~ ^[yY]$ ]]; then
  echo "⚠️ $LEVEL has not been destroyed."
  exit 0
fi

# Run terraform destroy
echo "🧨 Destroying module: $LEVEL"
terraform destroy -target=module.${LEVEL} -auto-approve > /dev/null

# Cleanup local files
echo "🧹 Cleaning up..."
if [ -d "start" ]; then
  rm -rf start
  echo "🗑 Completely removed 'start/' directory and its contents"
fi

# Remove active level tracker
if [ -f "$ACTIVE_FILE" ]; then
  rm -f "$ACTIVE_FILE"
  echo "🗑 Removed $ACTIVE_FILE"
fi

echo "✅ Level '$LEVEL' has been destroyed successfully."
