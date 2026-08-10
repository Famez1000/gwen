# Firebase Cloud Functions for Gwyn AI

https://console.firebase.google.com/u/0/project/mijnfb-c0a3b/functions?pli=1
https://console.firebase.google.com/u/0/project/mijnfb-c0a3b/appcheck

Spending cap:
https://aistudio.google.com/spend?project=gen-lang-client-0593289816 

Gwyn should not ship the Gemini API key inside the mobile app. The app calls a
Firebase HTTPS Cloud Function, and the function reads `GEMINI_API_KEY` from
Firebase secrets.

## One-time setup

Install the Firebase CLI and sign in:

```bash
npm install -g firebase-tools
firebase login
```

Connect this repo to your Firebase project:

```bash
firebase use --add
```

Store the Gemini API key as a Firebase secret:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

Deploy the function:

```bash
firebase deploy --only functions:gwenAi
```

After deployment, Firebase prints an HTTPS URL for `gwenAi`. Use that URL as
the app's `GWEN_AI_FUNCTION_URL`.
Function URL (gwenAi(us-central1)): https://gwenai-bf2iljcfjq-uc.a.run.app 

## Build for deploy:
For Android:
```bash
flutter build appbundle --release --dart-define=GWEN_AI_FUNCTION_URL=https://gwenai-bf2iljcfjq-uc.a.run.app
```

For iOS:
```bash
flutter build ios --release --no-codesign --dart-define=GWEN_AI_FUNCTION_URL=https://gwenai-bf2iljcfjq-uc.a.run.app
```

## Codemagic

Add an environment variable in Codemagic:

```text
GWEN_AI_FUNCTION_URL=https://gwenai-bf2iljcfjq-uc.a.run.app 
```

The current `codemagic.yaml` passes this variable to Flutter with
`--dart-define`.

## Google Play refund review RTDN

The `googlePlayRtdn` function listens for Google Play Real-time Developer
Notifications on the Pub/Sub topic `play-rtdn`. When Google sends a
`pendingRefundReviewNotification`, the function calls the Android Publisher
`orders.reviewrefund` API with a neutral refund preference.

Deploy it with:

```bash
firebase deploy --only functions:googlePlayRtdn --force
```

One-time Play/Firebase setup:

1. Create or select a Pub/Sub topic named `play-rtdn` in the Firebase
   project.
2. In Play Console, enable Real-time Developer Notifications for Gwyn and set
   the topic to `projects/mijnfb-c0a3b/topics/play-rtdn`.
3. Enable the Google Play Android Developer API in the Google Cloud project.
4. Give the Cloud Functions runtime service account permission to call the
   Android Publisher API for the Play Console app.
5. If the package name ever changes, set the function environment variable
   `PLAY_PACKAGE_NAME`; otherwise it defaults to `nl.mlmasters.anxietyslayer`.

The current implementation does not yet store a server-side purchase ledger, so
it cannot automatically submit detailed usage history. Add backend purchase
verification and entitlement records later if you want stronger evidence than a
neutral response.

## Security Notes

- Do not commit `apikey.txt`, `.env`, keystores, or Firebase secret values.
- Consider enabling Firebase App Check before production traffic grows.
- If abuse becomes a concern, require Firebase Auth or App Check verification in
  the function before calling Gemini.

Function URL (gwenAi(us-central1)): https://gwenai-bf2iljcfjq-uc.a.run.app 
https://console.firebase.google.com/project/mijnfb-c0a3b/overview

The actual AI workflow is:
User types/sends a message in ChatScreen.
_sendGeminiResponse() calls either generateGwenResponse() or generateContextualGwenResponse() at [chat_screen.dart (line 157)](/d:/Antigravity/DealingWithAnxiety/lib/features/chat/presentation/chat_screen.dart:157).
GeminiService posts JSON like { operation, payload } to the Firebase function URL at [gemini_service.dart (line 81)](/d:/Antigravity/DealingWithAnxiety/lib/core/services/gemini_service.dart:81).
Firebase gwenAi receives the request, builds the Gemini prompt/body based on operation, then calls Gemini with the secret key at [functions/index.js (line 9)](/d:/Antigravity/DealingWithAnxiety/functions/index.js:9).
Firebase returns { text }.
Flutter parses text and adds Gwyn’s reply to the chat. If the request fails, ChatScreen falls back to a local canned supportive response.
So: app users never receive the Gemini key. They only hit your Firebase function. The current Gwyn image tap mostly gates users into SubscriptionScreen; AI starts when a feature calls GeminiService.

Firebase security audit: the main weakness is the publicly accessible AI function.
High: gwenAi accepts anonymous requests. A live unauthenticated request reached its handler and returned its custom 405 response. There is no Firebase Auth, App Check, or rate limiting in [functions/index.js (line 19)](D:/Antigravity/DealingWithAnxiety/functions/index.js:19). This enables Gemini quota/cost abuse.
High: Request sizes are unbounded, including journal text and base64 drawings. requireString() only checks for non-empty input at [functions/index.js (line 369)](D:/Antigravity/DealingWithAnxiety/functions/index.js:369). Combined with 80-request concurrency and 20 deployed instances, this creates denial-of-service and billing exposure.
Medium: CORS allows every origin (cors: true) at [functions/index.js (line 24)](D:/Antigravity/DealingWithAnxiety/functions/index.js:24). CORS is not authentication, but this makes browser-based abuse easier.
Medium: Both functions use the project’s default Compute Engine service account. A dedicated least-privilege account should be used, especially for the Google Play refund function. I could not inspect its project IAM roles because gcloud is not installed.
Medium: npm audit found 11 production dependency findings: 1 high, 9 moderate, and 1 low. Updating firebase-admin requires testing a major upgrade to 14.x.
Good: GEMINI_API_KEY is deployed through Firebase Secret Manager, not embedded in the app.
Good: No secret files were found tracked by Git; apikey.txt and logs are ignored.
Good: googlePlayRtdn is an Eventarc/Pub/Sub trigger rather than a normal public HTTP handler.
Note: No Firestore, Realtime Database, or Storage rules are present in [firebase.json (line 1)](D:/Antigravity/DealingWithAnxiety/firebase.json:1). That is fine only if those Firebase products are not enabled or used.

Recommended priority: add App Check or authenticated callable access, enforce per-field/body limits, introduce server-side rate limits and Gemini quotas, then move each function to a dedicated least-privilege service account and update dependencies. No files or deployed settings were changed.

App Check setup:
https://console.firebase.google.com/u/0/project/mijnfb-c0a3b/appcheck/apps 
For the production app, get it from Google Play Console:
Open Google Play Console.
Select Gwyn.
Go to Setup → App integrity.
Open App signing.
Under App signing key certificate, copy the SHA‑256 certificate fingerprint.
Paste that value into Firebase.
Use the App signing key certificate, not the separate upload key certificate. Google Play signs the version installed by users with the app-signing key. See Play App Signing documentation.
For local/debug builds, obtain the debug fingerprint with:
cd android
.\gradlew.bat signingReport
cd ..
Find this section:
Variant: debug
SHA-256: AA:BB:CC:...
