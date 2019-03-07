workflow "build and deploy" {
  resolves = [
    "GitHub Action for Firebase",
  ]
  on = "push"
}

action "frontend install" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "install --prefix ./frontpage ./frontpage"
}

action "GitHub Action for Firebase" {
  uses = "w9jds/firebase-action@7d6b2b058813e1224cdd4db255b2f163ae4084d3"
  needs = [
    "functions build",
    "frontend build",
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

action "frontend test" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "run test --prefix ./frontpage "
  needs = ["frontend install"]
}

action "GitHub Action for npm-1" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "run build-css --prefix ./frontpage "
  runs = "frontpage build-css"
  needs = ["frontend test"]
}

action "frontend build" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  needs = ["GitHub Action for npm-1"]
  args = "run build --prefix ./frontpage "
}
