#!/bin/bash
binary="$0"
parameters="$@"
echo "${binary} ${parameters}" >> mockArgs
stdin=$(cat -)
echo "${binary} ${stdin}" >> mockStdin

function mockShouldFail() {
  [ "${MOCK_RETURNS[${binary}]}" = "_${parameters}" ]
}

source mockReturns
if [ ! -z "${MOCK_RETURNS[${binary}]}" ] || [ ! -z "${MOCK_RETURNS[${binary} $1]}" ]; then
  if mockShouldFail ; then
    exit 1
  fi
  if [ ! -z "${MOCK_RETURNS[${binary} $1]}" ]; then
    echo ${MOCK_RETURNS[${binary} $1]}
    exit 0
  fi
  echo ${MOCK_RETURNS[${binary}]}
fi

exit 0
