# digilocker
# digilocker

## Configuration

This project requires configuration files with secret keys. To set up:

1. Copy `Configuration.template.plist` to `Configuration.plist`
2. Fill in your Firebase credentials in `Configuration.plist`
3. Add your `GoogleService-Info.plist` file from Firebase Console

Never commit the actual configuration files containing secrets.

For CI/CD, set the following environment variables:
- FIREBASE_API_KEY
- FIREBASE_PROJECT_ID
- FIREBASE_STORAGE_BUCKET
- FIREBASE_APP_ID
