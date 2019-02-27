#!/bin/sh -e

function itPushesMasterBranchToLatest() {
  export GITHUB_REF='refs/heads/master'
  result=$(exec /entrypoint.sh 'my/repository')
  expected="Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesBranchAsNameOfTheBranch() {
  export GITHUB_REF='refs/heads/myBranch'
  result=$(exec /entrypoint.sh 'my/repository')
  expected="Called mock with: build -t my/repository:myBranch .
Called mock with: push my/repository:myBranch"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  result=$(exec /entrypoint.sh 'my/repository')
  expected="Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

itPushesMasterBranchToLatest
itPushesBranchAsNameOfTheBranch
itPushesReleasesToLatest
