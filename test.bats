#!/usr/bin/env bats

setup(){
  export GITHUB_REF='refs/heads/master'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
}

teardown() {
  unset INPUT_SNAPSHOT
  unset INPUT_DOCKERFILE
  unset INPUT_REGISTRY
  unset INPUT_CACHE
  unset GITHUB_SHA
  unset INPUT_PULL_REQUESTS
  unset MOCK_ERROR_CONDITION
}

@test "it pushes master branch to latest" {
  export GITHUB_REF='refs/heads/master'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:latest .
Called /usr/local/bin/docker push my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes branch as name of the branch" {
  export GITHUB_REF='refs/heads/myBranch'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:myBranch .
Called /usr/local/bin/docker push my/repository:myBranch
::set-output name=tag::myBranch
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it converts dashes in branch to hyphens" {
  export GITHUB_REF='refs/heads/myBranch/withDash'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:myBranch-withDash .
Called /usr/local/bin/docker push my/repository:myBranch-withDash
::set-output name=tag::myBranch-withDash
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes tags to latest" {
  export GITHUB_REF='refs/tags/myRelease'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:latest .
Called /usr/local/bin/docker push my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes specific Dockerfile to latest" {
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh  export GITHUB_REF='refs/heads/master'

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -f MyDockerFileName -t my/repository:latest .
Called /usr/local/bin/docker push my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes a snapshot by sha and date in addition" {
  export INPUT_SNAPSHOT='true'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:latest -t my/repository:19700101010112169e .
Called /usr/local/bin/docker push my/repository:latest
Called /usr/local/bin/docker push my/repository:19700101010112169e
::set-output name=snapshot-tag::19700101010112169e
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it caches image from former build and uses it for snapshot" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker pull my/repository:latest
Called /usr/local/bin/docker build --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
Called /usr/local/bin/docker push my/repository:latest
Called /usr/local/bin/docker push my/repository:19700101010112169e
::set-output name=snapshot-tag::19700101010112169e
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it does not use the cache for building when pulling the former image failed" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'
  export MOCK_ERROR_CONDITION='pull my/repository:latest'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker pull my/repository:latest
Called /usr/local/bin/docker build -t my/repository:latest -t my/repository:19700101010112169e .
Called /usr/local/bin/docker push my/repository:latest
Called /usr/local/bin/docker push my/repository:19700101010112169e
::set-output name=snapshot-tag::19700101010112169e
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes branch by sha and date with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -f MyDockerFileName -t my/repository:latest -t my/repository:19700101010112169e .
Called /usr/local/bin/docker push my/repository:latest
Called /usr/local/bin/docker push my/repository:19700101010112169e
::set-output name=snapshot-tag::19700101010112169e
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it caches image from former build and uses it for snapshot with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker pull my/repository:latest
Called /usr/local/bin/docker build -f MyDockerFileName --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
Called /usr/local/bin/docker push my/repository:latest
Called /usr/local/bin/docker push my/repository:19700101010112169e
::set-output name=snapshot-tag::19700101010112169e
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes to another registry and adds the reference" {
  export INPUT_REGISTRY='my.Registry.io'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin my.Registry.io
Called /usr/local/bin/docker build -t my.Registry.io/my/repository:latest .
Called /usr/local/bin/docker push my.Registry.io/my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes to another registry and is ok when the reference is already present" {
  export INPUT_REGISTRY='my.Registry.io'
  export INPUT_NAME='my.Registry.io/my/repository'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin my.Registry.io
Called /usr/local/bin/docker build -t my.Registry.io/my/repository:latest .
Called /usr/local/bin/docker push my.Registry.io/my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes to another registry and removes the protocol from the reference" {
  export INPUT_REGISTRY='https://my.Registry.io'
  export INPUT_NAME='my/repository'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin https://my.Registry.io
Called /usr/local/bin/docker build -t my.Registry.io/my/repository:latest .
Called /usr/local/bin/docker push my.Registry.io/my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it caches the image from a former build" {
  export INPUT_CACHE='true'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker pull my/repository:latest
Called /usr/local/bin/docker build --cache-from my/repository:latest -t my/repository:latest .
Called /usr/local/bin/docker push my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes pull requests when configured" {
  export GITHUB_REF='refs/pull/24/merge'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_PULL_REQUESTS='true'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 .
Called /usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
::set-output name=tag::12169ed809255604e557a82617264e9c373faca7
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it pushes to the tag if configured in the name" {
  export INPUT_NAME='my/repository:custom-tag'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
Called /usr/local/bin/docker build -t my/repository:custom-tag .
Called /usr/local/bin/docker push my/repository:custom-tag
::set-output name=tag::custom-tag
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it uses buildargs for building, if configured" {
  export INPUT_BUILDARGS='MY_FIRST,MY_SECOND'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
::add-mask::MY_FIRST
::add-mask::MY_SECOND
Called /usr/local/bin/docker build --build-arg MY_FIRST --build-arg MY_SECOND -t my/repository:latest .
Called /usr/local/bin/docker push my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it uses buildargs for a single variable" {
  export INPUT_BUILDARGS='MY_ONLY'

  run /entrypoint.sh

  local expected="
Called /usr/local/bin/docker login -u USERNAME --password-stdin
::add-mask::MY_ONLY
Called /usr/local/bin/docker build --build-arg MY_ONLY -t my/repository:latest .
Called /usr/local/bin/docker push my/repository:latest
::set-output name=tag::latest
Called /usr/local/bin/docker logout"
  echo $output
  [ "$output" = "$expected" ]
}

@test "it errors when with.name was not set" {
  unset INPUT_NAME

  run /entrypoint.sh

  local expected="Unable to find the name. Did you set with.name?"
  echo $output
  [ "$status" -eq 1 ]
  echo "$output" | grep "$expected"
}

@test "it errors when with.username was not set" {
  unset INPUT_USERNAME

  run /entrypoint.sh

  local expected="Unable to find the username. Did you set with.username?"
  echo $output
  [ "$status" -eq 1 ]
  echo "$output" | grep "$expected"
}

@test "it errors when with.password was not set" {
  unset INPUT_PASSWORD

  run /entrypoint.sh

  local expected="Unable to find the password. Did you set with.password?"
  echo $output
  [ "$status" -eq 1 ]
  echo "$output" | grep "$expected"
}

@test "it errors when the working directory is configured but not present" {
  export INPUT_WORKDIR='mySubDir'

  run /entrypoint.sh

  [ "$status" -eq 2 ]
}
