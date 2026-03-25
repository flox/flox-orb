#!/bin/bash

COMMAND="${PARAM_COMMAND}"
ENVIRONMENT="${PARAM_ENV}"
DIR="${PARAM_DIR}"

if [ "$COMMAND" == "" ]; then
  echo "command parameter is required."
  exit 2
fi

ACTIVATE="flox activate"
if [ "$ENVIRONMENT" != "" ]; then
  ACTIVATE="$ACTIVATE --reference=$ENVIRONMENT"
fi
if [ "$DIR" != "" ]; then
  ACTIVATE="$ACTIVATE --dir=$DIR"
fi

ACTIVATE="$ACTIVATE -- $COMMAND"

echo "Running: $ACTIVATE"

eval "$ACTIVATE"
