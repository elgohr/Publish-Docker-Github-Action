#!/bin/sh
parameters="$@"
echo "Called $0 ${parameters}"
if [ "${MOCK_ERROR_CONDITION}" = "${parameters}" ]; then
  exit 1
fi
exit 0
