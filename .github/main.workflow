workflow "On Push" {
  resolves = [
    "logout",
  ]
  on = "push"
}

action "login" {
  uses = "actions/docker/login@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  secrets = [
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD",
  ]
  env = {
    DOCKER_REGISTRY_URL = "docker.pkg.github.com"
  }
}

action "publish" {
  uses = "elgohr/Publish-Docker-Github-Action@1.0"
  args = "docker.pkg.github.com/elgohr/publish-docker-github-action/publish-docker-github-action:latest"
  needs = ["login"]
}

action "logout" {
  uses = "actions/docker/cli@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  args = "logout"
  needs = ["publish"]
}
