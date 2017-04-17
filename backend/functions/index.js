const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

/*exports.makeUppercase = functions.database.ref('/channels/{channelType}/{channelId}/topics/{topicId}/messages/{messageId}/text')
    .onWrite(event => {
      // Grab the current value of what was written to the Realtime Database.
      const original = event.data.val();
      console.log('Uppercasing ', original);
      const uppercase = original.toUpperCase();
      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to the Firebase Realtime Database.
      // Setting an "uppercase" sibling in the Realtime Database returns a Promise.
      return event.data.ref.parent.child('uppercase').set(uppercase);
    });*/

exports.smashmouth = functions.database.ref('/channels/{channelType}/{channelId}/topics/{topicId}/messages/{messageId}')
    .onWrite(event => {
      // Grab the current value of what was written to the Realtime Database.
      const original = event.data.child("text").val().toLowerCase();
      const triggerWords = ["hey now", "rockstar", "smashmouth", "bee movie"];
      var triggered = false;
      for (var i = 0; i < triggerWords.length; i++) {
        if (original.includes(triggerWords[i])) {
          triggered = true;
          break;
        }
      }
      if (triggered) {
        console.log('You are a rockstar!', original);
        const message = {
          senderId: "smashmouthbot",
          text: "You might enjoy this: https://www.youtube.com/watch?v=IxC2f0BL90g",
          timestamp: event.data.child("timestamp").val() + 1 // right after the message
        };
        return event.data.ref.parent.push().set(message);
      }
    });



