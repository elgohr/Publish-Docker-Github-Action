#!/bin/sh -e

function cleanEnvironment() {
  unset INPUT_snapshot
  unset INPUT_dockerfile
}

function itPushesMasterBranchToLatest() {
  export GITHUB_REF='refs/heads/master'
  local result=$(exec /entrypoint.sh 'my/repository')
  local expected="Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesBranchAsNameOfTheBranch() {
  export GITHUB_REF='refs/heads/myBranch'
  local result=$(exec /entrypoint.sh 'my/repository')
  local expected="Called mock with: build -t my/repository:myBranch .
Called mock with: push my/repository:myBranch"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  local result=$(exec /entrypoint.sh 'my/repository')
  local expected="Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesSpecificDockerfileReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_dockerfile='MyDockerFileName'
  local result=$(exec /entrypoint.sh 'my/repository')
  local expected="Called mock with: build -f MyDockerFileName -t my/repository:latest .
Called mock with: push my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesBranchByShaInAddition() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_snapshot='true'
  local result=$(exec env 'github.sha'=COMMIT_SHA /entrypoint.sh 'my/repository')
  local expected="Called mock with: build -t my/repository:latest -t my/repository:COMMIT_SHA .
Called mock with: push my/repository:latest
Called mock with: push my/repository:COMMIT_SHA"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesBranchByShaInAdditionWithSpecificDockerfile() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_snapshot='true'
  export INPUT_dockerfile='MyDockerFileName'
  local result=$(exec env 'github.sha'=COMMIT_SHA /entrypoint.sh 'my/repository')
  local expected="Called mock with: build -f MyDockerFileName -t my/repository:latest -t my/repository:COMMIT_SHA .
Called mock with: push my/repository:latest
Called mock with: push my/repository:COMMIT_SHA"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

itPushesMasterBranchToLatest
itPushesBranchAsNameOfTheBranch
itPushesReleasesToLatest
itPushesSpecificDockerfileReleasesToLatest
itPushesBranchByShaInAddition
itPushesBranchByShaInAdditionWithSpecificDockerfile
