workflow "build and deploy" {
  resolves = ["GitHub Action for Firebase", "frontend", "functions"]
  on = "release"
}

action "frontend" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "install --prefix ./frontpage ./frontpage"
}

action "GitHub Action for Firebase" {
  uses = "w9jds/firebase-action@7d6b2b058813e1224cdd4db255b2f163ae4084d3"
  needs = ["frontend", "functions"]
  secrets = ["FIREBASE_TOKEN"]
  args = "deploy"
}

action "functions" {
  uses = "actions/npm@59b64a598378f31e49cb76f27d6f3312b582f680"
  args = "install --prefix ./functions ./functions"
}
