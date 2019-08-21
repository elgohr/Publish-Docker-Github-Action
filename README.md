# Publishes docker containers to Dockerhub
[![Actions Status](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/badge/elgohr/Publish-Docker-Github-Action)](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/results/elgohr/Publish-Docker-Github-Action)

This Action for [Docker](https://www.docker.com/) uses the Git branch as the [Docker tag](https://docs.docker.com/engine/reference/commandline/tag/) for building and pushing the container to DockerHub.
Hereby the master-branch is published as the latest-tag.

## Usage

### New workflow
```yaml
name: Publish Docker
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Login to Registry
      run: docker login -u ${{ secrets.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_PASSWORD }}
    - name: Publish to Registry
      uses: elgohr/Publish-Docker-Github-Action@master
      with:
        args: myDocker/repository
    - name: Logout
      run: docker logout
```

#### Optional Arguments

Use `snapshot` to push an additional image, which is tagged with the git sha.  
When you would like to think about versioning images, this might be useful.  

```yaml
with:
  args: myDocker/repository
  snapshot: true
```


### Old workflow
```hcl
workflow "Publish Docker" {
  on = "push"
  resolves = ["logout"]
}

action "login" {
  uses = "actions/docker/login@master"
  secrets = ["DOCKER_PASSWORD", "DOCKER_USERNAME"]
}

action "publish" {
  uses = "elgohr/Publish-Docker-Github-Action@master"
  args = "myDocker/repository"
  needs = ["login"]
}

action "logout" {
  uses = "actions/docker/cli@master"
  args = "logout"
  needs = ["publish"]
}
```

## Docker builds

Please see https://github.com/elgohr/Publish-Docker-Github-Action/packages

## Argument

You need to provide the desired docker repository to the action.
