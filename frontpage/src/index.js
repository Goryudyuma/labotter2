import "./main.css";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";

registerServiceWorker();

firebase.auth().onAuthStateChanged(function(user) {
  if (user) {
    // User is signed in.
    var displayName = user.displayName;
    var uid = user.uid;
    var db = firebase.firestore();
    var mydb = db.collection("users").doc(uid);

    const app = Elm.Main.init({
      node: document.getElementById("root")
    });

    mydb.onSnapshot(function(mydata) {
      app.ports.updatelabonow.send(mydata.data().labonow);
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
    app.ports.laboin.subscribe(() => {
      db.runTransaction(function(transaction) {
        // This code may get re-run multiple times if there are conflicts.
        return transaction.get(mydb).then(function(mydata) {
          if (mydata.exists) {
            if (mydata.data().labonow === false) {
              transaction.update(mydb, {
                history: firebase.firestore.FieldValue.arrayUnion(Date.now())
              });
            }
            transaction.update(mydb, {
              labonow: true
            });
          }
        });
      });
    });

    // laboout
    app.ports.laboout.subscribe(() => {
      db.runTransaction(function(transaction) {
        // This code may get re-run multiple times if there are conflicts.
        return transaction.get(mydb).then(function(mydata) {
          if (mydata.exists) {
            if (mydata.data().labonow === true) {
              transaction.update(mydb, {
                history: firebase.firestore.FieldValue.arrayUnion(Date.now())
              });
            }
            transaction.update(mydb, {
              labonow: false
            });
          }
        });
      });
    });
  } else {
    // User is signed out.

    // Initialize the FirebaseUI Widget using Firebase.
    var ui = new firebaseui.auth.AuthUI(firebase.auth());

    var uiConfig = {
      callbacks: {
        signInSuccessWithAuthResult: function(authResult, redirectUrl) {
          // User successfully signed in.
          // Return type determines whether we continue the redirect automatically
          // or whether we leave that to developer to handle.
          return true;
        },
        uiShown: function() {
          // The widget is rendered.
          // Hide the loader.
          document.getElementById("loader").style.display = "none";
        }
      },
      // Will use popup for IDP Providers sign-in flow instead of the default, redirect.
      signInFlow: "popup",
      signInSuccessUrl: "/",
      signInOptions: [
        // Leave the lines as is for the providers you want to offer your users.
        firebase.auth.GoogleAuthProvider.PROVIDER_ID
        //    firebase.auth.FacebookAuthProvider.PROVIDER_ID,
        //    firebase.auth.TwitterAuthProvider.PROVIDER_ID,
        //    firebase.auth.GithubAuthProvider.PROVIDER_ID,
        //    firebase.auth.EmailAuthProvider.PROVIDER_ID,
        //    firebase.auth.PhoneAuthProvider.PROVIDER_ID
      ],
      // Terms of service url.
      tosUrl: "<your-tos-url>",
      // Privacy policy url.
      privacyPolicyUrl: "<your-privacy-policy-url>"
    };

    // The start method will wait until the DOM is loaded.
    ui.start("#firebaseui-auth-container", uiConfig);
  }
});
