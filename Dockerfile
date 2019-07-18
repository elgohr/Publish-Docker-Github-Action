FROM docker:18.09.8 as runtime
LABEL "com.github.actions.name"="Publish Docker"
LABEL "com.github.actions.description"="Uses the git branch as the docker tag and pushes the container"
LABEL "com.github.actions.icon"="anchor"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="https://github.com/elgohr/Publish-Docker-Github-Action"
LABEL "maintainer"="Lars Gohr"

RUN apk update \
  && apk upgrade \
  && apk add --no-cache git

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as test
ADD test.sh /test.sh
ADD mock.sh /fake_bin/docker
# Use mock instead of real docker
ENV PATH="/bin:/fake_bin"
RUN /test.sh

FROM runtime
