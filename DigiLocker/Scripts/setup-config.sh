#!/bin/sh

# Setup Configuration.plist
if [ ! -f "./DigiLocker/Config/Configuration.plist" ]; then
    cp "./DigiLocker/Config/Configuration.template.plist" "./DigiLocker/Config/Configuration.plist"
    
    # Replace placeholders with actual values from environment variables
    sed -i '' "s/YOUR_API_KEY/$FIREBASE_API_KEY/g" "./DigiLocker/Config/Configuration.plist"
    sed -i '' "s/YOUR_PROJECT_ID/$FIREBASE_PROJECT_ID/g" "./DigiLocker/Config/Configuration.plist"
    sed -i '' "s/YOUR_STORAGE_BUCKET/$FIREBASE_STORAGE_BUCKET/g" "./DigiLocker/Config/Configuration.plist"
    sed -i '' "s/YOUR_APP_ID/$FIREBASE_APP_ID/g" "./DigiLocker/Config/Configuration.plist"
fi

# Setup GoogleService-Info.plist
if [ ! -f "./DigiLocker/GoogleService-Info.plist" ]; then
    cp "./DigiLocker/Config/GoogleService-Info.template.plist" "./DigiLocker/GoogleService-Info.plist"
    
    # Replace placeholders with actual values from environment variables
    sed -i '' "s/YOUR_API_KEY/$FIREBASE_API_KEY/g" "./DigiLocker/GoogleService-Info.plist"
    sed -i '' "s/YOUR_GCM_SENDER_ID/$FIREBASE_GCM_SENDER_ID/g" "./DigiLocker/GoogleService-Info.plist"
    sed -i '' "s/YOUR_PROJECT_ID/$FIREBASE_PROJECT_ID/g" "./DigiLocker/GoogleService-Info.plist"
    sed -i '' "s/YOUR_STORAGE_BUCKET/$FIREBASE_STORAGE_BUCKET/g" "./DigiLocker/GoogleService-Info.plist"
    sed -i '' "s/YOUR_GOOGLE_APP_ID/$FIREBASE_APP_ID/g" "./DigiLocker/GoogleService-Info.plist"
fi 