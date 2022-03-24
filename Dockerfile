FROM docker:20.10.14@sha256:6d51c80ff60c5af6672cd56b99a19bee907503fbb5602e2d89d82c529029afef as runtime
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
