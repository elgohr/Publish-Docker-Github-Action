#!/bin/sh
set -e

if [ -z "${INPUT_NAME}" ]; then
  echo "Unable to find the repository name. Did you set with.name?"
  exit 1
fi

if [ -z "${INPUT_USERNAME}" ]; then
  echo "Unable to find the username. Did you set with.username?"
  exit 1
fi

if [ -z "${INPUT_PASSWORD}" ]; then
  echo "Unable to find the password. Did you set with.password?"
  exit 1
fi

BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g" | sed -e "s/\//-/g")

if [ "${BRANCH}" = "master" ]; then
  BRANCH="latest"
fi;

# if contains /refs/tags/
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/pull\///g") != ${GITHUB_REF} ]; then
  if [ -z "${INPUT_PULL_REQUESTS}" ]; then
    echo "The build was triggered within a pull request, but was not configured to build pull requests. Please see with.pull_requests"
    exit 1
  fi
  BRANCH="pr$(echo ${GITHUB_REF} | sed -e "s/refs\/pull\///g" | sed -e "s/\///g")"
fi;

echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

DOCKERNAME="${INPUT_NAME}:${BRANCH}"
BUILDPARAMS=""

if [ ! -z "${INPUT_DOCKERFILE}" ]; then
  BUILDPARAMS="$BUILDPARAMS -f ${INPUT_DOCKERFILE}"
fi

if [ ! -z "${INPUT_CACHE}" ]; then
  docker pull ${DOCKERNAME}
  BUILDPARAMS="$BUILDPARAMS --cache-from ${DOCKERNAME}"
fi

if [ "${INPUT_SNAPSHOT}" = "true" ]; then
  timestamp=`date +%Y%m%d%H%M%S`
  shortSha=$(echo "${GITHUB_SHA}" | cut -c1-6)
  SHA_DOCKER_NAME="${INPUT_NAME}:${timestamp}${shortSha}"
  docker build $BUILDPARAMS -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} .
  docker push ${DOCKERNAME}
  docker push ${SHA_DOCKER_NAME}
else
  docker build $BUILDPARAMS -t ${DOCKERNAME} .
  docker push ${DOCKERNAME}
fi

docker logout
