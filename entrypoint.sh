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

# if it's a tag
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

# if it's a pull request
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/pull\///g") != ${GITHUB_REF} ]; then
  BRANCH="${GITHUB_SHA}"
fi;

if [ ! -z "${INPUT_WORKDIR}" ]; then
  cd "${INPUT_WORKDIR}"
fi

echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

DOCKERNAME="${INPUT_NAME}:${BRANCH}"
BUILDPARAMS=""

if [ ! -z "${INPUT_DOCKERFILE}" ]; then
  BUILDPARAMS="$BUILDPARAMS -f ${INPUT_DOCKERFILE}"
fi

if [ ! -z "${INPUT_CACHE}" ]; then
  if docker pull ${DOCKERNAME} 2>/dev/null; then
    BUILDPARAMS="$BUILDPARAMS --cache-from ${DOCKERNAME}"
  fi
fi

if [ "${INPUT_SNAPSHOT}" = "true" ]; then
  TIMESTAMP=`date +%Y%m%d%H%M%S`
  SHORT_SHA=$(echo "${GITHUB_SHA}" | cut -c1-6)
  SNAPSHOT_TAG="${TIMESTAMP}${SHORT_SHA}"
  SHA_DOCKER_NAME="${INPUT_NAME}:${SNAPSHOT_TAG}"
  docker build $BUILDPARAMS -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} .
  docker push ${DOCKERNAME}
  docker push ${SHA_DOCKER_NAME}
  echo ::set-output name=snapshot-tag::"${SNAPSHOT_TAG}"
else
  docker build $BUILDPARAMS -t ${DOCKERNAME} .
  docker push ${DOCKERNAME}
fi
echo ::set-output name=tag::"${BRANCH}"

docker logout
