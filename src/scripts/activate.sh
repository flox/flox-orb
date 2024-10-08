#!/bin/bash

COMMAND="${PARAM_COMMAND}"
ENVIRONMENT="${PARAM_ENV}"

if [ "$COMMAND" == "" ]; then
  echo "command parameter is required."
  exit 2
fi

ACTIVATE="flox activate"
if [ "$ENVIRONMENT" != "" ]; then
  ACTIVATE="$ACTIVATE --remote=$ENVIRONMENT"
fi

ACTIVATE="$ACTIVATE -- $COMMAND"

echo "Running: $ACTIVATE"

eval "$ACTIVATE"
