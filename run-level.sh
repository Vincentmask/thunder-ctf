#!/bin/bash
set -e

LEVEL=$1
ACTIVE_FILE="config/active_level.txt"

if [ -z "$LEVEL" ]; then
  echo "Usage: ./run-level.sh <level_module_name>"
  echo "Example: ./run-level.sh a1openbucket"
  exit 1
fi

echo "🚀 Deploying level: $LEVEL"
terraform apply -target=module.${LEVEL} -auto-approve > /dev/null

# Write active level to config
echo "$LEVEL" > "$ACTIVE_FILE"

# Run the script
if [ "$LEVEL" = "a2finance" ]; then
  sleep 2
  python3 modules/a2finance/a2finance_provision.py
fi


echo
echo "✅ Level deployed!"

echo
echo "📜 Level Instructions:"
cat instructions/$LEVEL.txt

