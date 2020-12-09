#!/usr/bin/env bats

setup(){
  cat /dev/null >| mockArgs
  cat /dev/null >| mockStdin

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
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

@test "it pushes main branch to latest" {
  export GITHUB_REF='refs/heads/main'

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes master branch to latest" {
  export GITHUB_REF='refs/heads/master'

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes branch as name of the branch" {
  export GITHUB_REF='refs/heads/myBranch'

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::myBranch"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:myBranch .
/usr/local/bin/docker push my/repository:myBranch"
}

@test "it converts dashes in branch to hyphens" {
  export GITHUB_REF='refs/heads/myBranch/withDash'

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::myBranch-withDash"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:myBranch-withDash .
/usr/local/bin/docker push my/repository:myBranch-withDash"
}

@test "it pushes tags to latest" {
  export GITHUB_REF='refs/tags/myRelease'

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:latest
/usr/local/bin/docker logout"
}

@test "with tag names it pushes tags using the name" {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_TAG_NAMES="true"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::myRelease"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:myRelease .
/usr/local/bin/docker push my/repository:myRelease"
}

@test "with tag names set to false it doesn't push tags using the name" {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_TAG_NAMES="false"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "with tag semver it pushes tags using the major and minor versions (single digit)" {
  export GITHUB_REF='refs/tags/v1.2.3'
  export INPUT_TAG_SEMVER="true"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::1.2.3"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:1.2.3 -t my/repository:1.2 -t my/repository:1 .
/usr/local/bin/docker push my/repository:1.2.3
/usr/local/bin/docker push my/repository:1.2
/usr/local/bin/docker push my/repository:1
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:1.2.3
/usr/local/bin/docker logout"
}

@test "with tag semver it pushes tags using the major and minor versions (multi digits)" {
  export GITHUB_REF='refs/tags/v12.345.5678'
  export INPUT_TAG_SEMVER="true"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::12.345.5678"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12.345.5678 -t my/repository:12.345 -t my/repository:12 .
/usr/local/bin/docker push my/repository:12.345.5678
/usr/local/bin/docker push my/repository:12.345
/usr/local/bin/docker push my/repository:12
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:12.345.5678
/usr/local/bin/docker logout"
}

@test "with tag semver it pushes tags using the pre-release, but does not update the major, minor or patch version" {
  # as pre-release versions tend to be unstable
  # https://semver.org/#spec-item-11

  SUFFIXES=('alpha.1' 'alpha' 'ALPHA' 'ALPHA.11' 'beta' 'rc.11')
  for SUFFIX in "${SUFFIXES[@]}"
  do
    export GITHUB_REF="refs/tags/v1.1.1-${SUFFIX}"
    export INPUT_TAG_SEMVER="true"

    run /entrypoint.sh

    expectStdOutContains "::set-output name=tag::1.1.1-${SUFFIX}"

    expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:1.1.1-${SUFFIX} .
/usr/local/bin/docker push my/repository:1.1.1-${SUFFIX}
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:1.1.1-${SUFFIX}
/usr/local/bin/docker logout"
  done
}

@test "with tag semver it pushes tags without 'v' prefix" {
  export GITHUB_REF='refs/tags/1.2.34'
  export INPUT_TAG_SEMVER="true"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::1.2.34"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:1.2.34 -t my/repository:1.2 -t my/repository:1 .
/usr/local/bin/docker push my/repository:1.2.34
/usr/local/bin/docker push my/repository:1.2
/usr/local/bin/docker push my/repository:1
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:1.2.34
/usr/local/bin/docker logout"
}

@test "with tag semver it pushes latest when tag has invalid semver version" {
  export GITHUB_REF='refs/tags/vAA.BB.CC'
  export INPUT_TAG_SEMVER="true"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "with tag semver set to false it doesn't push tags using semver" {
  export GITHUB_REF='refs/tags/v1.2.34'
  export INPUT_TAG_NAMES="false"

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "it pushes specific Dockerfile to latest" {
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh  export GITHUB_REF='refs/heads/master'

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build -f MyDockerFileName -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "it pushes a snapshot by sha and date in addition" {
  export INPUT_SNAPSHOT='true'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectStdOutContains "
::set-output name=snapshot-tag::19700101010112169e
::set-output name=tag::latest"

  expectMockCalledContains "/usr/bin/date +%Y%m%d%H%M%S
/usr/local/bin/docker build -t my/repository:latest -t my/repository:19700101010112169e .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:19700101010112169e"
}

@test "it does not push a snapshot by sha and date in addition when turned off" {
  export INPUT_SNAPSHOT='false'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectStdOutContains "
::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "it caches image from former build and uses it for snapshot" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:latest
/usr/bin/date +%Y%m%d%H%M%S
/usr/local/bin/docker build --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:19700101010112169e"
}

@test "it does not use the cache for building when pulling the former image failed" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']="_pull my/repository:latest" # errors when pulled
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker pull my/repository:latest
/usr/bin/date +%Y%m%d%H%M%S
/usr/local/bin/docker build -t my/repository:latest -t my/repository:19700101010112169e .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:19700101010112169e"
}

@test "it pushes branch by sha and date with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectMockCalledContains "
/usr/bin/date +%Y%m%d%H%M%S
/usr/local/bin/docker build -f MyDockerFileName -t my/repository:latest -t my/repository:19700101010112169e .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:19700101010112169e"
}

@test "it caches image from former build and uses it for snapshot with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker pull my/repository:latest
/usr/bin/date +%Y%m%d%H%M%S
/usr/local/bin/docker build -f MyDockerFileName --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker push my/repository:19700101010112169e"
}

@test "it pushes to another registry and adds the hostname" {
  export INPUT_REGISTRY='my.Registry.io'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin my.registry.io
/usr/local/bin/docker build -t my.registry.io/my/repository:latest .
/usr/local/bin/docker push my.registry.io/my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my.registry.io/my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and is ok when the hostname is already present" {
  export INPUT_REGISTRY='my.Registry.io'
  export INPUT_NAME='my.Registry.io/my/repository'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin my.registry.io
/usr/local/bin/docker build -t my.registry.io/my/repository:latest .
/usr/local/bin/docker push my.registry.io/my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my.registry.io/my/repository:latest
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and removes the protocol from the hostname" {
  export INPUT_REGISTRY='https://my.Registry.io'
  export INPUT_NAME='my/repository'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin https://my.registry.io
/usr/local/bin/docker build -t my.registry.io/my/repository:latest .
/usr/local/bin/docker push my.registry.io/my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my.registry.io/my/repository:latest
/usr/local/bin/docker logout"
}

@test "it caches the image from a former build" {
  export INPUT_CACHE='true'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker pull my/repository:latest
/usr/local/bin/docker build --cache-from my/repository:latest -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "it does not cache the image from a former build if set to false" {
  export INPUT_CACHE='false'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest"
}

@test "it pushes pull requests when configured" {
  export GITHUB_REF='refs/pull/24/merge'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_PULL_REQUESTS='true'

  run /entrypoint.sh

  expectStdOutContains "
::set-output name=tag::12169ed809255604e557a82617264e9c373faca7"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7"
}

@test "it pushes to the tag if configured in the name" {
  export INPUT_NAME='my/repository:custom-tag'

  run /entrypoint.sh

  expectStdOutContains "
::set-output name=tag::custom-tag"

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:custom-tag .
/usr/local/bin/docker push my/repository:custom-tag"
}

@test "it uses buildargs for building, if configured" {
  export INPUT_BUILDARGS='MY_FIRST,MY_SECOND'

  run /entrypoint.sh

  expectStdOutContains "
::add-mask::MY_FIRST
::add-mask::MY_SECOND
::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build --build-arg MY_FIRST --build-arg MY_SECOND -t my/repository:latest ."
}

@test "it uses buildargs for a single variable" {
  export INPUT_BUILDARGS='MY_ONLY'

  run /entrypoint.sh

  expectStdOutContains "
::add-mask::MY_ONLY
::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker build --build-arg MY_ONLY -t my/repository:latest ."
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

@test "it can set a custom context" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_CONTEXT='/myContextFolder'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest /myContextFolder"
}

@test "it can set a custom context when building snapshot" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_CONTEXT='/myContextFolder'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export INPUT_SNAPSHOT='true'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker build -t my/repository:latest -t my/repository:19700101010112169e /myContextFolder"
}

@test "it populates the digest" {
  export GITHUB_REF='refs/heads/master'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker inspect']="my/repository@sha256:53b76152042486bc741fe59f130bfe683b883060c8284271a2586342f35dcd0e"
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectStdOutContains "::set-output name=digest::my/repository@sha256:53b76152042486bc741fe59f130bfe683b883060c8284271a2586342f35dcd0e"

  expectMockCalledContains "/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:latest"
}

@test "it uses buildoptions for building, if configured" {
  export INPUT_BUILDOPTIONS='--compress --force-rm'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker build --compress --force-rm -t my/repository:latest ."
}

@test "it uses buildoptions for building with snapshot, if configured" {
  export INPUT_BUILDOPTIONS='--compress --force-rm'
  export INPUT_SNAPSHOT='true'

  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ['/usr/bin/date']="197001010101"
  ) > mockReturns

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker build --compress --force-rm -t my/repository:latest -t my/repository:19700101010112169e ."
}

@test "it provides a possibility to define multiple tags" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_TAGS='A,B,C'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:A -t my/repository:B -t my/repository:C .
/usr/local/bin/docker push my/repository:A
/usr/local/bin/docker push my/repository:B
/usr/local/bin/docker push my/repository:C
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:A
/usr/local/bin/docker logout"
}

@test "it provides a possibility to define one tag" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_TAGS='A'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:A .
/usr/local/bin/docker push my/repository:A
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:A
/usr/local/bin/docker logout"
}

@test "it caches the first image when multiple tags defined" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_TAGS='A,B'
  export INPUT_CACHE='true'

  run /entrypoint.sh

  expectMockCalledContains "/usr/local/bin/docker pull my/repository:A
/usr/local/bin/docker build --cache-from my/repository:A -t my/repository:A -t my/repository:B .
/usr/local/bin/docker push my/repository:A
/usr/local/bin/docker push my/repository:B"
}

@test "it is verbose on ACTIONS_STEP_DEBUG" {
  export GITHUB_REF='refs/heads/master'
  export ACTIONS_STEP_DEBUG=true

  run /entrypoint.sh

  expectStdOutContains "::add-mask::USERNAME
::add-mask::PASSWORD
+ sanitize my/repository name"
}

@test "it is ok with complexer passwords" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_PASSWORD='9eL89n92G@!#o^$!&3Nz89F@%9'

  run /entrypoint.sh

  expectMockArgs '/usr/local/bin/docker 9eL89n92G@!#o^$!&3Nz89F@%9'
}

@test "it can be used for building only" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_NO_PUSH='true'

  run /entrypoint.sh

  expectStdOutIs ""

  expectMockCalledIs "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker logout"
}

@test "it can be used for building without login" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_NO_PUSH='true'
  export INPUT_USERNAME=''

  run /entrypoint.sh

  expectStdOutIs ""

  expectMockCalledIs "/usr/local/bin/docker build -t my/repository:latest ."
}

@test "it can change the default branch" {
  export GITHUB_REF='refs/heads/trunk'
  export INPUT_DEFAULT_BRANCH='trunk'

  run /entrypoint.sh

  expectStdOutContains "::set-output name=tag::latest"

  expectMockCalledContains "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:latest .
/usr/local/bin/docker push my/repository:latest
/usr/local/bin/docker inspect --format={{index .RepoDigests 0}} my/repository:latest
/usr/local/bin/docker logout"
}

expectStdOutIs() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(echo "${output}" | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  [ "${got}" == "${expected}" ]
}

expectStdOutContains() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(echo "${output}" | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  echo "${got}" | grep "${expected}"
}

expectMockCalledIs() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(cat mockArgs | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  [ "${got}" == "${expected}" ]
}

expectMockCalledContains() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(cat mockArgs | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  echo "${got}" | grep "${expected}"
}

expectMockArgs() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(cat mockStdin | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  echo "${got}" | grep "${expected}"
}
