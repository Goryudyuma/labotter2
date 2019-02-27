import "./main.css";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";
import firebaseui from "firebaseui";
import firebase from "firebase";

// Initialize Firebase
const config = {
  apiKey: "AIzaSyBiBBVV6O357R9ARQCvhmJAIB08ZA469EQ",
  authDomain: "labotter2.firebaseapp.com",
  databaseURL: "https://labotter2.firebaseio.com",
  projectId: "labotter2",
  storageBucket: "labotter2.appspot.com",
  messagingSenderId: "216536496923"
};
firebase.initializeApp(config);

registerServiceWorker();

let app = Elm.Main.init({
  node: document.getElementById("root")
});

firebase.auth().setPersistence(firebase.auth.Auth.Persistence.LOCAL);

function register(result) {
  if (result.credential) {
    // Accounts successfully linked.
    if (result.additionalUserInfo.providerId === "twitter.com") {
      const credential = result.credential;
      const user = result.user;
      const uid = user.uid;
      const db = firebase.firestore();
      const mydb = db.collection("users").doc(uid);

      const batch = db.batch();
      batch.update(mydb, { twitter: true });
      batch.update(mydb.collection("credential").doc("twitter"), {
        accessToken: credential.accessToken,
        secret: credential.secret
      });
      batch.commit();
    }
  }
  return true;
}

firebase
  .auth()
  .getRedirectResult()
  .then(register)
  .catch(function(error) {
    // Handle Errors here.
    // ...
  });

firebase.auth().onAuthStateChanged(function(user) {
  if (user) {
    app.ports.userlogin.send(true);

    // User is signed in.
    const displayName = user.displayName;
    const uid = user.uid;
    const db = firebase.firestore();
    const mydb = db.collection("users").doc(uid);

    mydb.onSnapshot(mydata => {
      app.ports.updatelabointime.send(mydata.data().labointime);
      app.ports.updatelabotimes.send(mydata.data().history);
    });

    // logout
    app.ports.logout.subscribe(() => {
      firebase
        .auth()
        .signOut()
        .then(() => {
          location.reload();
        });
    });

    // laboin
    app.ports.laboin.subscribe(labointime => {
      db.runTransaction(function(transaction) {
        // This code may get re-run multiple times if there are conflicts.
        return transaction.get(mydb).then(function(mydata) {
          if (mydata.exists) {
            transaction.update(mydb, {
              labointime: labointime
            });
          }
        });
      });

      firebase.functions().httpsCallable("laboin")();
    });

    // laboout
    app.ports.laboout.subscribe(laboouttime => {
      db.runTransaction(function(transaction) {
        // This code may get re-run multiple times if there are conflicts.
        return transaction.get(mydb).then(function(mydata) {
          if (mydata.exists) {
            if (mydata.data().labointime !== 0) {
              transaction.update(mydb, {
                history: firebase.firestore.FieldValue.arrayUnion({
                  labointime: mydata.data().labointime,
                  laboouttime: laboouttime
                })
              });
            }
            transaction.update(mydb, {
              labointime: 0
            });
          }
        });
      });

      firebase.functions().httpsCallable("laboout")();
    });

    // link twitter
    app.ports.link_twitter.subscribe(() => {
      const provider = new firebase.auth.TwitterAuthProvider();
      firebase.auth().currentUser.linkWithRedirect(provider);
    });

    // unlink twitter
    app.ports.unlink_twitter.subscribe(() => {
      user.unlink("twitter.com");
    });
  }
});

// Initialize the FirebaseUI Widget using Firebase.
let ui = new firebaseui.auth.AuthUI(firebase.auth());

const uiConfig = {
  callbacks: {
    signInSuccessWithAuthResult: function(authResult, redirectUrl) {
      // User successfully signed in.
      // Return type determines whether we continue the redirect automatically
      // or whether we leave that to developer to handle.
      return register(authResult);
    },
    uiShown: function() {
      // The widget is rendered.
      // Hide the loader.
      // document.getElementById("loader").style.display = "none";
    }
  },
  // Will use popup for IDP Providers sign-in flow instead of the default, redirect.
  signInFlow: "popup",
  signInSuccessUrl: "/",
  signInOptions: [
    // Leave the lines as is for the providers you want to offer your users.
    firebase.auth.TwitterAuthProvider.PROVIDER_ID,
    firebase.auth.GoogleAuthProvider.PROVIDER_ID,
    firebase.auth.FacebookAuthProvider.PROVIDER_ID,
    firebase.auth.GithubAuthProvider.PROVIDER_ID,
    firebase.auth.EmailAuthProvider.PROVIDER_ID,
    firebase.auth.PhoneAuthProvider.PROVIDER_ID
  ],
  // Terms of service url.
  tosUrl: "/",
  // Privacy policy url.
  privacyPolicyUrl: "/"
};

// The start method will wait until the DOM is loaded.
ui.start("#firebaseui-auth-container", uiConfig);
