workflow "Publish" {
  resolves = [
    "test",
  ]
  on = "push"
}

action "test" {
  uses = "actions/docker/cli@master"
  args = "build ."
}
