#!/bin/sh -l

DOCKER_REPOSITORY=$*

BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g")
if [ "${BRANCH}" = "master" ]; then
    BRANCH="latest"
fi;

DOCKERNAME="${DOCKER_REPOSITORY}:${BRANCH}"

docker build -t ${DOCKERNAME} .
docker push ${DOCKERNAME}
