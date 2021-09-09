FROM docker:20.10.8@sha256:ddf0d732dcbc3e2087836e06e50cc97e21bfb002a49c7d0fe767f6c31e01d65f as runtime
LABEL "repository"="https://github.com/elgohr/Publish-Docker-Github-Action"
LABEL "maintainer"="Lars Gohr"

RUN apk update \
  && apk upgrade \
  && apk add --no-cache git

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as testEnv
RUN apk add --no-cache coreutils bats
ADD test.bats /test.bats
ADD mock.sh /usr/local/bin/docker
ADD mock.sh /usr/bin/date
RUN /test.bats

FROM runtime
