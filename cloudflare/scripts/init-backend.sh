#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed."
    exit 1
fi

python3 "$SCRIPT_DIR/init-backend.py"
