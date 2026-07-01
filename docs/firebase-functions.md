# Firebase Cloud Functions for Gwen AI

Gwen should not ship the Gemini API key inside the mobile app. The app calls a
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

## Local build

Build the app with the deployed function URL:

```bash
flutter build appbundle --release --dart-define=GWEN_AI_FUNCTION_URL=https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/gwenAi
```

For iOS:

```bash
flutter build ios --release --no-codesign --dart-define=GWEN_AI_FUNCTION_URL=https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/gwenAi
```

## Codemagic

Add an environment variable in Codemagic:

```text
GWEN_AI_FUNCTION_URL=https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/gwenAi
```

The current `codemagic.yaml` passes this variable to Flutter with
`--dart-define`.

## Security Notes

- Do not commit `apikey.txt`, `.env`, keystores, or Firebase secret values.
- Consider enabling Firebase App Check before production traffic grows.
- If abuse becomes a concern, require Firebase Auth or App Check verification in
  the function before calling Gemini.
