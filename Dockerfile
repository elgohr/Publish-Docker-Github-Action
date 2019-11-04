FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine as runtime
LABEL "repository"="https://github.com/elgohr/Publish-Docker-Github-Action"
LABEL "maintainer"="Lars Gohr"

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime as testEnv
RUN apk add --no-cache coreutils bats ncurses
ADD test.bats /test.bats
ADD mock.sh /usr/local/bin/docker
ADD mock.sh /usr/bin/date
RUN /test.bats

FROM runtime
