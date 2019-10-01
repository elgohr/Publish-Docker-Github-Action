#!/bin/sh
set -e

echo "" # see https://github.com/actions/toolkit/issues/168

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

function translateTag() {
  BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g" | sed -e "s/\//-/g")
  # if there is a tag inside the name already
  if [ $(echo ${INPUT_NAME} | sed -e "s/://g") != ${INPUT_NAME} ]; then
    TAG=$(echo ${INPUT_NAME} | cut -d':' -f2)
    INPUT_NAME=$(echo ${INPUT_NAME} | cut -d':' -f1)
  elif [ "${BRANCH}" = "master" ]; then
    TAG="latest"
  # if it's a tag
  elif [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
    TAG="latest"
  # if it's a pull request
  elif [ $(echo ${GITHUB_REF} | sed -e "s/refs\/pull\///g") != ${GITHUB_REF} ]; then
    TAG="${GITHUB_SHA}"
  else
    TAG="${BRANCH}"
  fi;
}

translateTag
DOCKERNAME="${INPUT_NAME}:${TAG}"

if [ ! -z "${INPUT_WORKDIR}" ]; then
  cd "${INPUT_WORKDIR}"
fi

echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

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
echo ::set-output name=tag::"${TAG}"

docker logout
