FROM docker:19.03.2 as runtime
LABEL "repository"="https://github.com/laeubli/Publish-Docker-Github-Action"
LABEL "maintainer"="Samuel Läubli"

RUN apk update \
  && apk upgrade \
  && apk add --no-cache bash openssh-client git

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as testEnv
RUN apk add --no-cache coreutils bats ncurses
ADD test.bats /test.bats
ADD stub.sh /usr/local/bin/docker
ADD mock.sh /usr/bin/date
RUN /test.bats

FROM runtime
