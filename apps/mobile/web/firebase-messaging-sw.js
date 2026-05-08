// Firebase Cloud Messaging service worker (web).
//
// Minimal v1.5 stub: registers the messaging SDK so the browser can
// receive cheer-up pushes when the tab is in the background. The actual
// notification render path is handled by the FCM SDK's default handler;
// we override only when product copy or click behaviour requires it,
// which is deferred until the cheer-up Cloud Function lands (5.5b).
//
// Configuration values are intentionally placeholders — the Cloud
// Function signs payloads with the project's server key; the web client
// only needs the public web app config to subscribe. Wiring the live
// config happens in the FCM toggle dispatch follow-up (6.3 polish), not
// in this scaffolding pass.

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js',
);

// Placeholder config — real values are injected at deploy time. The SDK
// tolerates a missing config object as long as the page itself initializes
// Firebase before requesting a token.
self.firebase &&
  self.firebase.initializeApp({
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
  });

// Hook the messaging instance so the browser knows this SW is FCM-aware.
// We deliberately do NOT register an `onBackgroundMessage` handler yet —
// the default SDK behaviour shows the notification from the payload's
// `notification` block, which is what `sendCheerUpPush` will emit.
if (self.firebase && self.firebase.messaging) {
  self.firebase.messaging();
}
