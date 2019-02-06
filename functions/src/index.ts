import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp(functions.config().firebase);

const db = admin.firestore();
const settings = { timestampsInSnapshots: true };
db.settings(settings);

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
//export const helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
//});

export const firstLogin = functions.auth.user().onCreate(user => {
  return db
    .collection("users")
    .doc(user.uid.toString())
    .set({ labonow: false, twitter: false })
    .then(() => {
      return db
        .collection("users")
        .doc(user.uid.toString())
        .collection("credential")
        .doc("twitter")
        .set({ accessToken: "", secret: "" });
    });
});

export const deleteUser = functions.auth.user().onDelete(user => {
  return db
    .collection("users")
    .doc(user.uid.toString())
    .delete().then(() => {
      return db
        .collection("users")
        .doc(user.uid.toString())
        .collection("credential")
        .doc("twitter")
        .delete()
    });
});
