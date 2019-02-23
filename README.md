# Publishes docker containers to Dockerhub

This Action for [Docker](https://www.docker.com/) uses the Git branch as the Docker tag for building and pushing the container to DockerHub.
Hereby the master-branch is published as the latest-tag.

## Usage

An example workflow:

```hcl
workflow "Publish Docker" {
  on = "push"
  resolves = ["logout"]
}

action "login" {
  uses = "actions/docker/login@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  secrets = ["DOCKER_PASSWORD", "DOCKER_USERNAME"]
}

action "publish" {
  uses = "actions/publish-docker@master"
  args = "myDocker/repository"
  needs = ["login"]
}

action "logout" {
  uses = "actions/docker/cli@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  args = "logout"
  needs = ["publish"]
}
```

## Argument

You need to provide the desired docker repository to the action.
