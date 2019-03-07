workflow "build and deploy" {
  resolves = [
    "GitHub Action for Firebase",
  ]
  on = "push"
}

action "frontpage install" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "install --prefix ./frontpage ./frontpage"
}

action "GitHub Action for Firebase" {
  uses = "w9jds/firebase-action@7d6b2b058813e1224cdd4db255b2f163ae4084d3"
  needs = [
    "Filter master",
  ]
  secrets = ["FIREBASE_TOKEN"]
  args = "deploy"
  env = {
    PROJECT_ID = "labotter2"
  }
}

action "functions install" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "install --prefix ./functions ./functions"
}

action "functions lint" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  needs = ["functions install"]
  args = "run lint --prefix ./functions"
}

action "functions build" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  needs = ["functions lint"]
  args = "run build --prefix ./functions "
}

action "frontpage test" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "run test --prefix ./frontpage "
  needs = ["frontpage install"]
}

action "frontpage build-css" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "run build-css --prefix ./frontpage "
  needs = ["frontpage install"]
}

action "frontpage build" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "run build --prefix ./frontpage "
  needs = ["frontpage test", "frontpage build-css"]
}

action "Filter master" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  needs = ["frontpage build", "functions build"]
  args = "branch master"
}
