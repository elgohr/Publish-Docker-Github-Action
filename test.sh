#!/bin/sh -e

echo "GITHUB_REF: $GITHUB_REF"
echo "GITHUB_HEAD_REF: $GITHUB_HEAD_REF"
echo "GITHUB_BASE_REF: $GITHUB_BASE_REF"
echo "GITHUB_WORKSPACE: $GITHUB_WORKSPACE"
echo "GITHUB_EVENT_NAME: $GITHUB_EVENT_NAME"

function cleanEnvironment() {
  unset INPUT_SNAPSHOT
  unset INPUT_DOCKERFILE
  unset GITHUB_SHA
}

function itOpensPullRequest() {
  export GITHUB_REF='refs/heads/master'
  export GITHUB_HEAD_REF='develop'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -t my/repository:develop .
Called mock with: push my/repository:develop
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesMasterBranchToLatest() {
  export GITHUB_REF='refs/heads/master'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesBranchAsNameOfTheBranch() {
  export GITHUB_REF='refs/heads/myBranch'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -t my/repository:myBranch .
Called mock with: push my/repository:myBranch
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesSpecificDockerfileReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_DOCKERFILE='MyDockerFileName'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -f MyDockerFileName -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesBranchByShaInAddition() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_SNAPSHOT='true'
  export GITHUB_SHA='COMMIT_SHA'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -t my/repository:latest -t my/repository:COMMIT_SHA .
Called mock with: push my/repository:latest
Called mock with: push my/repository:COMMIT_SHA
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesBranchByShaInAdditionWithSpecificDockerfile() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_SNAPSHOT='true'
  export INPUT_DOCKERFILE='MyDockerFileName'
  export GITHUB_SHA='COMMIT_SHA'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD
Called mock with: build -f MyDockerFileName -t my/repository:latest -t my/repository:COMMIT_SHA .
Called mock with: push my/repository:latest
Called mock with: push my/repository:COMMIT_SHA
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itLogsIntoAnotherRegistryIfConfigured() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_REGISTRY='https://myRegistry'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME -p PASSWORD https://myRegistry
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itErrorsWhenNameWasNotSet() {
  unset INPUT_NAME
  local result=$(exec /entrypoint.sh)
  local expected="Unable to find the repository name. Did you set with.name?"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itErrorsWhenUsernameWasNotSet() {
  export INPUT_NAME='my/repository'
  unset INPUT_USERNAME
  local result=$(exec /entrypoint.sh)
  local expected="Unable to find the username. Did you set with.username?"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itErrorsWhenPasswordWasNotSet() {
  export INPUT_NAME='my/repository'
  export INPUT_USERNAME='USERNAME'
  unset INPUT_PASSWORD
  local result=$(exec /entrypoint.sh)
  local expected="Unable to find the password. Did you set with.password?"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

itPushesMasterBranchToLatest
itPushesBranchAsNameOfTheBranch
itPushesReleasesToLatest
itPushesSpecificDockerfileReleasesToLatest
itPushesBranchByShaInAddition
itPushesBranchByShaInAdditionWithSpecificDockerfile
itLogsIntoAnotherRegistryIfConfigured
itErrorsWhenNameWasNotSet
itErrorsWhenUsernameWasNotSet
itErrorsWhenPasswordWasNotSet
