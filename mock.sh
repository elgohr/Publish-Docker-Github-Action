#!/bin/bash
binary="$0"
parameters="$@"
echo "${binary} ${parameters}" >> mockCalledWith

source mockReturns

overridenCommand="${binary} $1"
if [ ! -z "${MOCK_RETURNS[${overridenCommand}]}" ]; then
  if [ "${MOCK_RETURNS[${overridenCommand}]}" = "_" ] ; then
    exit 1
  fi
  echo "${MOCK_RETURNS[${overridenCommand}]}"
  exit 0
fi

if [ ! -z "${MOCK_RETURNS[${binary}]}" ]; then
  echo "${MOCK_RETURNS[${binary}]}"
fi

exit 0
