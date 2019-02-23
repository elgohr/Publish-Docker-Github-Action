#!/bin/sh -l

echo ${GITHUB_REF}
BRANCH=$(${GITHUB_REF} | sed -e "s/refs\/heads\///g")
echo ${BRANCH}
if [ "${BRANCH}" = "master" ]; then
    BRANCH="latest"
fi;
DOCKER_REPOSITORY=$*
DOCKERNAME="${DOCKER_REPOSITORY}:${BRANCH}"

docker build -t ${DOCKERNAME} .
docker push ${DOCKERNAME}
