#!/bin/bash
set -euo pipefail

COMMAND="${PARAM_COMMAND}"
ENVIRONMENT="${PARAM_ENV}"
DIR="${PARAM_DIR}"

if [ -z "$COMMAND" ]; then
  echo "command parameter is required."
  exit 2
fi

ACTIVATE="flox activate"
if [ -n "$ENVIRONMENT" ]; then
  ACTIVATE="$ACTIVATE -r=$ENVIRONMENT"
fi
if [ -n "$DIR" ]; then
  ACTIVATE="$ACTIVATE --dir=$DIR"
fi

ACTIVATE="$ACTIVATE -c \"$COMMAND\""

echo "Running: $ACTIVATE"

eval "$ACTIVATE"
