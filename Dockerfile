FROM docker:19.03.2 as runtime
LABEL "repository"="https://github.com/elgohr/Publish-Docker-Github-Action"
LABEL "maintainer"="Lars Gohr"

RUN apk update \
  && apk upgrade \
  && apk add --no-cache git

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as testEnv
RUN apk add --no-cache coreutils bats ncurses
ADD test.bats /test.bats
ADD mock.sh /usr/local/bin/docker
RUN /test.bats

FROM runtime
