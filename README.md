# Publishes docker containers
[![Actions Status](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/badge/elgohr/Publish-Docker-Github-Action)](https://wdp9fww0r9.execute-api.us-west-2.amazonaws.com/production/results/elgohr/Publish-Docker-Github-Action)

This Action for [Docker](https://www.docker.com/) uses the Git branch as the [Docker tag](https://docs.docker.com/engine/reference/commandline/tag/) for building and pushing the container.
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
    - name: Publish to Registry
      uses: elgohr/Publish-Docker-Github-Action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
```

## Mandatory Arguments

`name` is the name of the image you would like to push  
`username` the login username for the registry  
`password` the login password for the registry  

#### Optional Arguments

Use `registry` for pushing to a custom registry

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  registry: docker.pkg.github.com
```

Use `snapshot` to push an additional image, which is tagged with {YEAR}{MONTH}{DAY}{HOUR}{MINUTE}{SECOND}{first 6 digits of the git sha}.  
The date was inserted to prevent new builds with external dependencies override older builds with the same sha.
When you would like to think about versioning images, this might be useful.  

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  snapshot: true
```

Use `dockerfile` when you would like to explicitly build a Dockerfile.  
This might be useful when you have multiple DockerImages.  

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  dockerfile: MyDockerFileName
```

Use `cache` when you have big images, that you would only like to build partially (changed layers).  
> CAUTION: This will cache the non changed parts forever. If you use this option, make sure that these parts will be updated by another job!

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  cache: true
```
