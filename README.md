# Publishes docker containers
[![Actions Status](https://github.com/elgohr/Publish-Docker-Github-Action/workflows/Test/badge.svg)](https://github.com/elgohr/Publish-Docker-Github-Action/actions)
[![Actions Status](https://github.com/elgohr/Publish-Docker-Github-Action/workflows/Integration%20Test/badge.svg)](https://github.com/elgohr/Publish-Docker-Github-Action/actions)
[![Actions Status](https://github.com/elgohr/Publish-Docker-Github-Action/workflows/Integration%20Test%20Github/badge.svg)](https://github.com/elgohr/Publish-Docker-Github-Action/actions)

This Action for [Docker](https://www.docker.com/) uses the Git branch as the [Docker tag](https://docs.docker.com/engine/reference/commandline/tag/) for building and pushing the container.
Hereby the master-branch is published as the latest-tag.

## Usage

## Example pipeline
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
`password` the authentication token [preferred] or login password for the registry.

If you would like to publish the image to other registries, these actions might be helpful  

| Registry                                             | Action                                        |
|------------------------------------------------------|-----------------------------------------------|
| Amazon Webservices Elastic Container Registry (ECR)  | https://github.com/elgohr/ecr-login-action    |
| Google Cloud Container Registry                      | https://github.com/elgohr/gcloud-login-action |

## Outputs

`tag` is the tag, which was pushed  
`snapshot-tag` is the tag that is generated by the [snapshot-option](https://github.com/elgohr/Publish-Docker-Github-Action#snapshot) and pushed  
`digest` is the digest of the image, which was pushed  

## Optional Arguments

### registry
Use `registry` for pushing to a custom registry.
> NOTE: GitHub's Docker registry uses a different path format to Docker Hub, as shown below. See [Configuring Docker for use with GitHub Package Registry](https://help.github.com/en/github/managing-packages-with-github-package-registry/configuring-docker-for-use-with-github-package-registry#publishing-a-package) for more information.
If you're using GitHub Packages, you might also want to use `${{ github.actor }}` as the `username`.

```yaml
with:
  name: owner/repository/image
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  registry: docker.pkg.github.com
```

### snapshot
Use `snapshot` to push an additional image, which is tagged with  
`{YEAR}{MONTH}{DAY}{HOUR}{MINUTE}{SECOND}{first 6 digits of the git sha}`.  
The date was inserted to prevent new builds with external dependencies override older builds with the same sha.
When you would like to think about versioning images, this might be useful.  

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  snapshot: true
```

### dockerfile
Use `dockerfile` when you would like to explicitly build a Dockerfile.  
This might be useful when you have multiple DockerImages.  

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  dockerfile: MyDockerFileName
```

### workdir
Use `workdir` when you would like to change the directory for building.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  workdir: mySubDirectory
```

### context
Use `context` when you would like to change the Docker build context.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  context: myContextDirectory
```

### buildargs
Use `buildargs` when you want to pass a list of environment variables as [build-args](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg). Identifiers are separated by comma.   
All `buildargs` will be masked, so that they don't appear in the logs.  

```yaml
- name: Publish to Registry
  uses: elgohr/Publish-Docker-Github-Action@master
  env:
    MY_FIRST: variableContent
    MY_SECOND: variableContent
  with:
    name: myDocker/repository
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    buildargs: MY_FIRST,MY_SECOND
```

### buildoptions
Use `buildoptions` when you want to configure [options](https://docs.docker.com/engine/reference/commandline/build/#options) for building.  

```yaml
- name: Publish to Registry
  uses: elgohr/Publish-Docker-Github-Action@master
  with:
    name: myDocker/repository
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    buildoptions: "--compress --force-rm"
```

### cache
Use `cache` when you have big images, that you would only like to build partially (changed layers).  
> CAUTION: Docker builds will cache non-repoducable commands, such as installing packages. If you use this option, your packages will never update. To avoid this, run this action on a schedule with caching **disabled** to rebuild the cache periodically.

```yaml
name: Publish to Registry
on:
  push:
    branches:
      - master
  schedule:
    - cron: '0 2 * * 0' # Weekly on Sundays at 02:00
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Publish to Registry
      uses: elgohr/Publish-Docker-Github-Action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        cache: ${{ github.event_name != 'schedule' }}
```
### Tags

This action supports multiple options that tags are handled.  
By default a tag is pushed as `latest`.  
Furthermore, one of the following options can be used. 

#### tags
Use `tags` when you want to bring your own tags (separated by comma).  

```yaml
- name: Publish to Registry
  uses: elgohr/Publish-Docker-Github-Action@master
  with:
    name: myDocker/repository
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    tags: "latest,another"
```

When using dynamic tag names the environment variable must be set via echo, as variables set in the environment will not auto resolve by convention.  
This example illustrates how you would push to latest along with creating a custom version tag in a release. Setting it to only run on published events will keep your tags from being filled with commit hashes and will only publish when a GitHub release is created, so if the GitHub release is 2.14 this will publish to the latest and 2.14 tags.

```yaml
name: Publish to Registry
on:    
  release:
      types: [published]
  push:
    branches:
      - master
  schedule:
    - cron: '0 2 * * 0' # Weekly on Sundays at 02:00
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Get release version
      id: get_version
      run: echo ::set-env name=RELEASE_VERSION::$(echo ${GITHUB_REF:10})
    - name: Publish to Registry
      uses: elgohr/Publish-Docker-Github-Action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        tags: "latest,${{ env.RELEASE_VERSION }}"
```

#### tag_prefix
Use `tag_prefix` when you want add something before the tag you will push.  

```yaml
- name: Publish to Registry
  uses: elgohr/Publish-Docker-Github-Action@master
  with:
    name: myDocker/repository
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    tag_semver: true
    tag_prefix: "arm64-"
```

This allow you to set dynamic image name with strategy matrix for example. In this illustrated example, the image tag created will be ARM-1.0.0 and ARM64-1.0.0. the two images will be pushed in you're repository.

```yaml
name: Publish to Registry

jobs:
  update:
    runs-on: 
      - self-hosted
      - ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ARM, ARM64]
    steps:
    - uses: actions/checkout@master
    - name: Publish to Registry
      uses: elgohr/Publish-Docker-Github-Action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        tag_semver: true
        tag_prefix: ${{ matrix.os }}-
```

#### tag_names
Use `tag_names` when you want to push tags/release by their git name (e.g. `refs/tags/MY_TAG_NAME`).  
> CAUTION: Images produced by this feature can be override by branches with the same name - without a way to restore.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  tag_names: true
```

#### tag_semver
Use `tag_semver` when you want to push tags using the semver syntax by their git name (e.g. `refs/tags/v1.2.3`). This will push four
docker tags: `1.2.3`, `1.2` and `1`. A prefix 'v' will automatically be removed.
> CAUTION: Images produced by this feature can be override by branches with the same name - without a way to restore.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  tag_semver: true
```
