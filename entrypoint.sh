#!/bin/sh

DOCKER_REPOSITORY=$*
BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g")

if [ "${BRANCH}" == "master" ]; then
  BRANCH="latest"
fi;

# if contains /refs/tags/
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

DOCKERNAME="${DOCKER_REPOSITORY}:${BRANCH}"
CUSTOMDOCKERFILE=""

if [ ! -z "${INPUT_DOCKERFILE}" ]; then
  CUSTOMDOCKERFILE="-f ${INPUT_DOCKERFILE}"
fi


if [ "${INPUT_SNAPSHOT}" == "true" ]; then
  SHA_DOCKER_NAME="${DOCKER_REPOSITORY}:${GITHUB_SHA}"
  docker build $CUSTOMDOCKERFILE -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} .
  docker push ${DOCKERNAME}
  docker push ${SHA_DOCKER_NAME}
else
  docker build $CUSTOMDOCKERFILE -t ${DOCKERNAME} .
  docker push ${DOCKERNAME}
fi
