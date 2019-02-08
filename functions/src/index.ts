import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as twitter from "twitter";

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
    .delete()
    .then(() => {
      return db
        .collection("users")
        .doc(user.uid.toString())
        .collection("credential")
        .doc("twitter")
        .delete();
    });
});

const postTweet = (
  access_token: string,
  access_token_secret: string,
  content: string
) => {
  new twitter({
    access_token_key: access_token,
    access_token_secret: access_token_secret,
    consumer_key: functions.config().twitter.key,
    consumer_secret: functions.config().twitter.secret
  }).post("statuses/update", { status: content }, (error, tweet, response) => {
    if (!error) {
      console.log(tweet);
    }
    return response;
  });
};

export const laboin = functions.https.onCall((data, context) => {
  if (context.auth !== undefined) {
    const uid = context.auth.uid;
    return db.runTransaction(transaction => {
      return transaction.get(db.collection("users").doc(uid)).then(my => {
        const mydata = my.data();
        if (mydata !== undefined) {
          if (mydata.twitter) {
            return transaction
              .get(
                db
                  .collection("users")
                  .doc(uid)
                  .collection("credential")
                  .doc("twitter")
              )
              .then(credential => {
                const credential_data = credential.data();
                if (credential_data !== undefined) {
                  postTweet(
                    credential_data.accessToken,
                    credential_data.secret,
                    "test"
                  );
                }
              });
          }
        }
        return;
      });
    });
  }
  return "not login";
});
