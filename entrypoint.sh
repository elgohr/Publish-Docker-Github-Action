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

if [ "${INPUT_snapshot}" == "true" ]; then
  SHA=$(env | grep ^github\\.sha= | cut -d= -f2-) # Thank you Github for using dots in variables
  SHA_DOCKER_NAME="${DOCKER_REPOSITORY}:${SHA}"
  docker build -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} .
  docker push ${DOCKERNAME}
  docker push ${SHA_DOCKER_NAME}
else
  docker build -t ${DOCKERNAME} .
  docker push ${DOCKERNAME}
fi
