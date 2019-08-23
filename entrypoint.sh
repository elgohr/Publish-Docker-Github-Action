#!/bin/sh

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

# If a PR, then use the merging branch
[[ -z "$GITHUB_HEAD_REF" ]] && BRANCH="{GITHUB_HEAD_REF" || BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g")

if [ "${BRANCH}" == "master" ]; then
  BRANCH="latest"
fi;

# if contains /refs/tags/
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

DOCKERNAME="${INPUT_NAME}:${BRANCH}"
CUSTOMDOCKERFILE=""

if [ ! -z "${INPUT_DOCKERFILE}" ]; then
  CUSTOMDOCKERFILE="-f ${INPUT_DOCKERFILE}"
fi

docker login -u ${INPUT_USERNAME} -p ${INPUT_PASSWORD} ${INPUT_REGISTRY}

if [ "${INPUT_SNAPSHOT}" == "true" ]; then
  SHA_DOCKER_NAME="${INPUT_NAME}:${GITHUB_SHA}"
  docker build $CUSTOMDOCKERFILE -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} .
  docker push ${DOCKERNAME}
  docker push ${SHA_DOCKER_NAME}
else
  docker build $CUSTOMDOCKERFILE -t ${DOCKERNAME} .
  docker push ${DOCKERNAME}
fi

docker logout
