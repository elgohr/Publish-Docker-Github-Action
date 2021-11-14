FROM docker:20.10.9@sha256:62302357e804b152e157d3603ce7a97c3f368a626ce027eee1d1e02b5ae924f3 as runtime
LABEL "repository"="https://github.com/elgohr/Publish-Docker-Github-Action"
LABEL "maintainer"="Lars Gohr"
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as testEnv
RUN apk add --no-cache coreutils bats
ADD test.bats /test.bats
ADD mock.sh /usr/local/mock/docker
ADD mock.sh /usr/local/mock/date
RUN /test.bats

FROM runtime
