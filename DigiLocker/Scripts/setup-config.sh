#!/bin/sh

# Check if Configuration.plist exists
if [ ! -f "./DigiLocker/Config/Configuration.plist" ]; then
    cp "./DigiLocker/Config/Configuration.template.plist" "./DigiLocker/Config/Configuration.plist"
    
    # Replace placeholders with actual values from environment variables
    sed -i '' "s/YOUR_API_KEY/$FIREBASE_API_KEY/g" "./DigiLocker/Config/Configuration.plist"
    sed -i '' "s/YOUR_PROJECT_ID/$FIREBASE_PROJECT_ID/g" "./DigiLocker/Config/Configuration.plist"
    sed -i '' "s/YOUR_STORAGE_BUCKET/$FIREBASE_STORAGE_BUCKET/g" "./DigiLocker/Config/Configuration.plist"
    sed -i '' "s/YOUR_APP_ID/$FIREBASE_APP_ID/g" "./DigiLocker/Config/Configuration.plist"
fi 