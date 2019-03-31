workflow "Publish Docker" {
  resolves = [
    "logout",
  ]
  on = "release"
}

action "login" {
  uses = "actions/docker/login@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  secrets = ["DOCKER_PASSWORD", "DOCKER_USERNAME"]
}

action "publish" {
  uses = "elgohr/Publish-Docker-Github-Action@1.0"
  args = "lgohr/publish-docker-github-action"
  needs = ["login"]
}

action "logout" {
  uses = "actions/docker/cli@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  args = "logout"
  needs = ["publish"]
}

workflow "Release" {
  on = "push"
  resolves = ["create release"]
}

action "create release" {
  uses = "elgohr/Github-Hub-Action@1.0"
  args = "release create $(date +%Y%m%d%H%M%S)"
  secrets = ["GITHUB_TOKEN"]
}
