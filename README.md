# digilocker
# digilocker

## Configuration

This project requires configuration files with secret keys. To set up:

1. Copy `Configuration.template.plist` to `Configuration.plist`
2. Copy `GoogleService-Info.template.plist` to `GoogleService-Info.plist`
3. Fill in your Firebase credentials in both files

Never commit the actual configuration files containing secrets.

For CI/CD, set the following environment variables:
- FIREBASE_API_KEY
- FIREBASE_PROJECT_ID
- FIREBASE_STORAGE_BUCKET
- FIREBASE_APP_ID
- FIREBASE_GCM_SENDER_ID

You can find these values in your Firebase Console under Project Settings.
