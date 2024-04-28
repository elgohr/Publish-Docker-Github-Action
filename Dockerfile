FROM ubuntu:24.04@sha256:562456a05a0dbd62a671c1854868862a4687bf979a96d48ae8e766642cd911e8 as runtime
ENV DEBIAN_FRONTEND=noninteractive
COPY docker/01_nodoc /etc/dpkg/dpkg.cfg.d/
RUN apt-get update \
  && apt-get install -y ca-certificates curl gnupg lsb-release jq \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update -o Dir::Etc::sourcelist="sources.list.d/docker.list" \
         -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" \
  && apt-get install -y docker-ce docker-ce-cli containerd.io \
  && apt-get remove -y curl gnupg lsb-release \
  && rm /usr/libexec/docker/cli-plugins/docker-compose \
  && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

FROM runtime AS testEnv
RUN apt-get install -y coreutils bats \
  && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY test.bats /test.bats
COPY mock.sh /usr/local/mock/docker
COPY mock.sh /usr/local/mock/date
RUN /test.bats

FROM runtime
