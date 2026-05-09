// Firebase Cloud Messaging service worker (web).
//
// Registers the messaging SDK so the browser can receive cheer-up pushes
// when the tab is in the background. The default FCM SDK handler renders
// the notification from the payload's `notification` block, which is
// what `sendCheerUpPush` emits — no `onBackgroundMessage` override
// needed.
//
// The config values mirror `apps/mobile/lib/firebase_options.dart`'s
// `web` block. The browser permission API needs a registered SW with
// valid Firebase config to surface the prompt; placeholder values
// silently failed (v1.5 polish fix).

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js',
);

self.firebase &&
  self.firebase.initializeApp({
    apiKey: 'AIzaSyBEeN6AbPk3k5lTvx3j1ASnNzUeRbEYNeY',
    appId: '1:433750563013:web:7575f3acaf7dbd96a538ac',
    messagingSenderId: '433750563013',
    projectId: 'csc234-user-centric-mobile-app',
    authDomain: 'csc234-user-centric-mobile-app.firebaseapp.com',
    storageBucket: 'csc234-user-centric-mobile-app.firebasestorage.app',
  });

if (self.firebase && self.firebase.messaging) {
  self.firebase.messaging();
}
