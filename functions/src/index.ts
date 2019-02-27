import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as twitter from "twitter";

admin.initializeApp(functions.config().firebase);

const db = admin.firestore();

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
//export const helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
//});

const enum TweetState {
  Laboin = "laboin",
  Laboout = "laboout",
  Labonow = "labonow"
}

export const firstLogin = functions.auth.user().onCreate(user => {
  return db
    .collection("users")
    .doc(user.uid.toString())
    .set({
      labointime: 0,
      twitter: false,
      google: false,
      github: false,
      tweetContent: {
        laboin: "らぼいん!",
        laboout: "らぼりだ!",
        labonow: "らぼなう!"
      },
      history: []
    })
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
    return response;
  });
};

const makeTweet = (uid: string, tweetState: TweetState) => {
  return db.runTransaction(transaction => {
    return transaction.get(db.collection("users").doc(uid)).then(my => {
      const mydata = my.data();
      if (mydata !== undefined) {
        if (mydata.twitter) {
          const tweetContent: string = mydata.tweetContent[tweetState];
          if (tweetContent !== "" && tweetContent.length <= 140) {
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
                    tweetContent
                  );
                }
                return "ok";
              });
          } else {
            return 'wrong tweet content: "' + tweetContent + '"';
          }
        }
      }
      return "happened trouble";
    });
  });
};

export const laboin = functions.https.onCall((data, context) => {
  if (context.auth !== undefined) {
    const uid = context.auth.uid;
    return makeTweet(uid, TweetState.Laboin);
  }
  return "not login";
});

export const laboout = functions.https.onCall((data, context) => {
  if (context.auth !== undefined) {
    const uid = context.auth.uid;
    return makeTweet(uid, TweetState.Laboout);
  }
  return "not login";
});

export const labonow = functions.https.onCall((data, context) => {
  if (context.auth !== undefined) {
    const uid = context.auth.uid;
    return makeTweet(uid, TweetState.Labonow);
  }
  return "not login";
});
