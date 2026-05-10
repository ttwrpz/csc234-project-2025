// Cloud Functions entry point.
//
// Initialises the Firebase Admin SDK exactly once at module load. Without
// this, `getFirestore()` (used by the rate limiter) throws
// `"The default Firebase app does not exist"` — firebase-admin v13
// dropped the implicit auto-initialisation that earlier versions had. The
// resulting exception is caught by each handler's rate-limit try/catch
// and surfaced to the client as `code: "internal"`, which manifests as a
// silent 200-with-internal-error from the user's perspective. Calling
// `initializeApp()` with no args picks up Application Default
// Credentials provided by the Cloud Run runtime, so we don't need to
// pass project / credentials explicitly.

import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { analyzeMoodText } from './analyzeMoodText.js';
export { analyzePatterns } from './analyzePatterns.js';
export { sendCheerUpPush } from './sendCheerUpPush.js';
export { wipeUserData } from './wipeUserData.js';
export { wipeWeeklyGarden } from './wipeWeeklyGarden.js';
