#!/bin/sh
parameters="$@"
echo "Called mock with: ${parameters}"
if [ "${MOCK_ERROR_CONDITION}" = "${parameters}" ]; then
  exit 1
fi
exit 0
