FROM docker:20.10.11@sha256:ff4fcc30e7c20f33c021e82683aedd1fe66654363eb1ff61065e0628f5bbf107 as runtime
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
