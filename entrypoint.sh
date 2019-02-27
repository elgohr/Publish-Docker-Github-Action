#!/bin/sh

DOCKER_REPOSITORY=$*
BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g")

if [ "${BRANCH}" = "master" ]; then
  BRANCH="latest"
fi;

# if contains /refs/tags/
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

DOCKERNAME="${DOCKER_REPOSITORY}:${BRANCH}"

docker build -t ${DOCKERNAME} .
docker push ${DOCKERNAME}
