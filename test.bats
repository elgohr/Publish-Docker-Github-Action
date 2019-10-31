#!/usr/bin/env bats

setup(){
  cat /dev/null >| mockCalledWith

  currentYear=`date +%Y`
  nextYear=$(($currentYear+1))
  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/local/bin/docker history']="IMAGE               CREATED AT                  CREATED BY                                      SIZE                COMMENT
cf0f3ca922e0        $nextYear-10-18T20:48:51+02:00   /bin/sh -c #(nop)  CMD ['/bin/bash']            0
<missing>           2019-10-18T20:48:51+02:00   /bin/sh -c mkdir -p /run/systemd && echo 'do…   7"
  ) > mockReturns

  export GITHUB_REF='refs/heads/master'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
}

teardown() {
  unset INPUT_TAG_NAMES
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

  expectStdOut "
::set-output name=tag::latest"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes branch as name of the branch" {
  export GITHUB_REF='refs/heads/myBranch'

  run /entrypoint.sh

  expectStdOut "
::set-output name=tag::myBranch"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:myBranch .
/usr/local/bin/docker push my/repository:myBranch
/usr/local/bin/docker logout"
}

@test "it converts dashes in branch to hyphens" {
  export GITHUB_REF='refs/heads/myBranch/withDash'

  run /entrypoint.sh

  expectStdOut "
::set-output name=tag::myBranch-withDash"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:myBranch-withDash .
/usr/local/bin/docker push my/repository:myBranch-withDash
/usr/local/bin/docker logout"
}

@test "it pushes tags to latest" {
  export GITHUB_REF='refs/tags/myRelease'

  run /entrypoint.sh

  expectStdOut "
::set-output name=tag::latest"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
}

@test "with tag names it pushes tags using the name" {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_TAG_NAMES=true

  run /entrypoint.sh

  expectStdOut "
::set-output name=tag::myRelease"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:myRelease .
/usr/local/bin/docker push my/repository:myRelease
/usr/local/bin/docker logout"
}

@test "it pushes specific Dockerfile to latest" {
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh  export GITHUB_REF='refs/heads/master'

  expectStdOut "
::set-output name=tag::latest"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -f MyDockerFileName -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes a snapshot by sha and date in addition" {
  export INPUT_SNAPSHOT='true'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'

  run /entrypoint.sh

  tag="`date +%Y%m%d%H%M%S`12169e"
  expectStdOut "
::set-output name=snapshot-tag::$tag
::set-output name=tag::latest"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest -t my/repository:$tag .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:$tag
/usr/local/bin/docker logout"
}

@test "it caches image from former build and uses it for snapshot" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='3'

  run /entrypoint.sh

  tag="`date +%Y%m%d%H%M%S`12169e"
  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:latest
/usr/local/bin/docker history -H=false my/repository:latest
/usr/local/bin/docker build --cache-from my/repository:latest -t my/repository:latest -t my/repository:$tag .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:$tag
/usr/local/bin/docker logout"
}

@test "it does not use the cache for building when pulling the former image failed" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='3'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/local/bin/docker pull']="_" # errors when pulled
  ) > mockReturns

  run /entrypoint.sh

  tag="`date +%Y%m%d%H%M%S`12169e"
  echo $output
  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:latest
/usr/local/bin/docker build -t my/repository:latest -t my/repository:$tag .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:$tag
/usr/local/bin/docker logout"
}

@test "it pushes branch by sha and date with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  tag="`date +%Y%m%d%H%M%S`12169e"
  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -f MyDockerFileName -t my/repository:latest -t my/repository:$tag .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:$tag
/usr/local/bin/docker logout"
}

@test "it caches image from former build and uses it for snapshot with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='3'
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  echo $output
  tag="`date +%Y%m%d%H%M%S`12169e"
  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:latest
/usr/local/bin/docker history -H=false my/repository:latest
/usr/local/bin/docker build -f MyDockerFileName --cache-from my/repository:latest -t my/repository:latest -t my/repository:$tag .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:$tag
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and adds the hostname" {
  export INPUT_REGISTRY='my.Registry.io'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin my.Registry.io
/usr/local/bin/docker build -t my.Registry.io/my/repository:latest .
/usr/local/bin/docker push my.Registry.io/my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and is ok when the hostname is already present" {
  export INPUT_REGISTRY='my.Registry.io'
  export INPUT_NAME='my.Registry.io/my/repository'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin my.Registry.io
/usr/local/bin/docker build -t my.Registry.io/my/repository:latest .
/usr/local/bin/docker push my.Registry.io/my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and removes the protocol from the hostname" {
  export INPUT_REGISTRY='https://my.Registry.io'
  export INPUT_NAME='my/repository'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin https://my.Registry.io
/usr/local/bin/docker build -t my.Registry.io/my/repository:latest .
/usr/local/bin/docker push my.Registry.io/my/repository:latest
/usr/local/bin/docker logout"
}

@test "it caches the image from a former build" {
  export INPUT_CACHE=3

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:latest
/usr/local/bin/docker history -H=false my/repository:latest
/usr/local/bin/docker build --cache-from my/repository:latest -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
}

@test "it does not cache the image when older than retention period" {
  export INPUT_CACHE='1'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/local/bin/docker history']="IMAGE               CREATED AT                  CREATED BY                                      SIZE                COMMENT
cf0f3ca922e0        2019-10-18T20:48:51+02:00   /bin/sh -c #(nop)  CMD ['/bin/bash']            0
<missing>           2019-10-18T20:48:51+02:00   /bin/sh -c mkdir -p /run/systemd && echo 'do…   7"
  ) > mockReturns

  run /entrypoint.sh

  expectStdOut "
Retention period has been exceeded. Building without cache.
::set-output name=tag::latest"

  echo $ouput
  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:latest
/usr/local/bin/docker history -H=false my/repository:latest
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
}

@test "it warns when using the old caching syntax" {
  export INPUT_CACHE='true'

  run /entrypoint.sh

  expectStdOut "
Warning: Your build is using the deprecated INPUT_CACHE=true, please upgrade to a specific retention time as this feature will be removed in 3.x (see https://github.com/elgohr/Publish-Docker-Github-Action/tree/master#cache)
::set-output name=tag::latest"
}

@test "it pushes pull requests when configured" {
  export GITHUB_REF='refs/pull/24/merge'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_PULL_REQUESTS='true'

  run /entrypoint.sh

  expectStdOut "
::set-output name=tag::12169ed809255604e557a82617264e9c373faca7"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker logout"
}

@test "it pushes to the tag if configured in the name" {
  export INPUT_NAME='my/repository:custom-tag'

  run /entrypoint.sh

  expectStdOut "
::set-output name=tag::custom-tag"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:custom-tag .
/usr/local/bin/docker push my/repository:custom-tag
/usr/local/bin/docker logout"
}

@test "it uses buildargs for building, if configured" {
  export INPUT_BUILDARGS='MY_FIRST,MY_SECOND'

  run /entrypoint.sh

  expectStdOut "
::add-mask::MY_FIRST
::add-mask::MY_SECOND
::set-output name=tag::latest"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build --build-arg MY_FIRST --build-arg MY_SECOND -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
}

@test "it uses buildargs for a single variable" {
  export INPUT_BUILDARGS='MY_ONLY'

  run /entrypoint.sh

  expectStdOut "
::add-mask::MY_ONLY
::set-output name=tag::latest"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build --build-arg MY_ONLY -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker logout"
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

function expectStdOut() {
  echo "Expected: |$1|
  Got: |$output|"
  [ "$output" = "$1" ]
}

function expectMockCalled() {
  local mockCalledWith=$(cat mockCalledWith)
  echo "Expected: |$1|
  Got: |$mockCalledWith|"
  [ "$mockCalledWith" = "$1" ]
}
