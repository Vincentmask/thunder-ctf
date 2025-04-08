#!/bin/bash
set -e

LEVEL=$1

if [ -z "$LEVEL" ]; then
  echo "Usage: ./run-level.sh <level_module_name>"
  echo "Example: ./run-level.sh a1openbucket"
  exit 1
fi

echo "🚀 Deploying level: $LEVEL"
terraform apply -target=module.${LEVEL} -auto-approve > /dev/null

echo
echo "✅ Level deployed!"

echo
echo "🪣 Bucket Name:"
terraform output -raw bucket_name 2>/dev/null || terraform output module.${LEVEL}.bucket_name

echo
echo "📜 Level Instructions:"
terraform output -raw level_instructions 2>/dev/null || terraform output module.${LEVEL}.level_instructions
