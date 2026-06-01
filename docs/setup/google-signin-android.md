# Fixing "Google sign-in was cancelled" on Android

## Symptom

On Android, tapping **Continue with Google**, picking an account, and then
immediately getting a "Google sign-in was cancelled" result - even though the
user did not cancel.

## Root cause

The app code is correct:

- `apps/mobile/lib/main.dart` calls `GoogleSignIn.instance.initialize(serverClientId: <web client id>)`.
- `apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart`
  uses the google_sign_in 7.x API (`authenticate(scopeHint:)`) and mints a
  Firebase credential from the returned `idToken`.

The problem is in **Firebase project configuration**. `android/app/google-services.json`
currently contains only a **Web** OAuth client (`client_type: 3`) and **no
Android OAuth client** (`client_type: 1`) bound to the app's package name and
signing-certificate SHA-1.

On Android, google_sign_in 7.x drives Credential Manager. Without an Android
OAuth client whose SHA-1 matches the installed build's signing key, Credential
Manager cannot issue an ID token for this app, so it returns
`GoogleSignInExceptionCode.canceled` *after* the account picker - which the app
surfaces as "cancelled".

- Package name: `com.cssit.usercentricapp`
- google-services.json oauth_client types present today: `[3]` (Web only)

## Fix (Firebase console - one-time, no code change)

1. Get the signing-certificate SHA-1 of the build you run.

   Debug builds (default for `flutter run`):

   ```bash
   keytool -list -v \
     -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   ```

   On Windows the debug keystore is at
   `%USERPROFILE%\.android\debug.keystore`. Alternatively run
   `cd apps/mobile/android && ./gradlew signingReport` and read the `SHA1`
   for the `debug` variant. Copy the `SHA1:` value.

   > Tip: in this Claude Code session you can run the keytool command yourself
   > by typing it after a leading `!` in the prompt so its output appears here.

2. In the [Firebase console](https://console.firebase.google.com/), open the
   project `csc234-user-centric-mobile-app` -> **Project settings** -> **General**.

3. Under **Your apps**, select the Android app
   (`com.cssit.usercentricapp`). If it does not exist, click **Add app** ->
   Android and register it with that exact package name.

4. Click **Add fingerprint** and paste the SHA-1 from step 1. (Add the
   release keystore's SHA-1 too when you ship a release build signed with a
   real key - the current `build.gradle.kts` signs release with the debug
   key, so the debug SHA-1 covers both for now.)

5. Click **Download google-services.json** and replace
   `apps/mobile/android/app/google-services.json` with the new file. It will
   now include an `oauth_client` entry with `client_type: 1` (the Android
   client) bound to your SHA-1.

6. Rebuild the app (`flutter run`). Google sign-in will now complete.

## Verifying

After replacing google-services.json, confirm the Android client is present:

```bash
python -c "import json; d=json.load(open('apps/mobile/android/app/google-services.json')); print([o.get('client_type') for c in d['client'] for o in c.get('oauth_client',[])])"
```

The output should now include `1` (Android) in addition to `3` (Web).

## Note on the serverClientId

`main.dart` passes the **Web** client id as `serverClientId` - that is correct
and must stay. It tells Credential Manager which audience to mint the ID token
for so Firebase's `signInWithCredential` accepts it. The Android client
(client_type 1) is what authorizes *this app* to request that token; both are
required.
