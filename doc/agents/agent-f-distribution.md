# Agent F: Code Signing + Notarization + DMG

## Who You Are

You are the **distribution** agent for **OpenCue**. The app is fully built and polished. Your job is to configure code signing, notarize the app with Apple, and package it as a DMG for direct download.

You are working in **Round 4**, solo. All previous agents have completed their work. The app builds and runs correctly.

## Context

OpenCue is a native macOS teleprompter app. It is distributed as a direct download (NOT through the Mac App Store). This means:
- Code signing with **Developer ID Application** certificate (not Mac App Store)
- Hardened Runtime must be enabled
- App must be notarized by Apple (otherwise Gatekeeper blocks it)
- Delivered as a `.dmg` disk image

Read:
- `doc/prd.md` — Distribution section

## Prerequisites

Before you start, verify:
1. The app builds successfully: `xcodebuild -scheme OpenCue -configuration Release build`
2. A valid Apple Developer account is configured in Xcode
3. A "Developer ID Application" certificate exists in the keychain
4. An app-specific password or API key is available for notarization

**If any of these are missing, STOP and document what the user needs to set up.** Do not proceed without valid signing credentials.

## What You Must Do

### 1. Configure Xcode Project Signing

Open the Xcode project and verify/update these settings:

**In `OpenCue.xcodeproj`:**
- Signing & Capabilities tab:
  - Team: The user's Developer ID team
  - Signing Certificate: "Developer ID Application"
  - Bundle Identifier: `com.opencue.app`
- Build Settings:
  - `CODE_SIGN_IDENTITY` = "Developer ID Application"
  - `DEVELOPMENT_TEAM` = (user's team ID)
  - `ENABLE_HARDENED_RUNTIME` = YES
  - `CODE_SIGN_STYLE` = Manual (recommended for distribution builds)

**Entitlements:**
Create `OpenCue/OpenCue.entitlements` if it doesn't exist. Minimal entitlements for this app:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

The app does NOT use the sandbox (we need unrestricted access for global hotkeys and NSPanel configuration). Since we're not on the Mac App Store, sandbox is not required.

If the app uses any of these, add the corresponding entitlement:
- Accessibility API (for global hotkeys): May need `com.apple.security.automation.apple-events`
- However, `NSEvent.addGlobalMonitorForEvents` typically works without special entitlements in non-sandboxed apps

### 2. Archive the App

```bash
# Clean build
xcodebuild clean -scheme OpenCue -configuration Release

# Archive
xcodebuild archive \
  -scheme OpenCue \
  -configuration Release \
  -archivePath ./build/OpenCue.xcarchive
```

### 3. Export the Archive

```bash
# Create an exportOptions.plist
cat > ./build/exportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>TEAM_ID_HERE</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
EOF

# Export
xcodebuild -exportArchive \
  -archivePath ./build/OpenCue.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ./build/exportOptions.plist
```

Replace `TEAM_ID_HERE` with the actual team ID.

### 4. Notarize the App

```bash
# Zip the app for notarization
ditto -c -k --keepParent ./build/export/OpenCue.app ./build/OpenCue.zip

# Submit for notarization
xcrun notarytool submit ./build/OpenCue.zip \
  --apple-id "USER_APPLE_ID" \
  --team-id "TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD" \
  --wait

# Alternative: use API key
# xcrun notarytool submit ./build/OpenCue.zip \
#   --key "AuthKey_XXXXXXXXXX.p8" \
#   --key-id "KEY_ID" \
#   --issuer "ISSUER_ID" \
#   --wait
```

**If notarization fails:**
- Check the log: `xcrun notarytool log <submission-id> --apple-id ... --team-id ... --password ...`
- Common issues:
  - Missing hardened runtime
  - Unsigned frameworks or dylibs
  - Missing entitlements for protected APIs

### 5. Staple the Notarization Ticket

```bash
# Staple to the .app
xcrun stapler staple ./build/export/OpenCue.app

# Verify
xcrun stapler validate ./build/export/OpenCue.app
spctl -a -vvv ./build/export/OpenCue.app
```

### 6. Create DMG

**Option A: Using create-dmg (recommended, prettier)**

```bash
# Install if needed
brew install create-dmg

# Create DMG
create-dmg \
  --volname "OpenCue" \
  --volicon "./OpenCue/OpenCue/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 160 \
  --icon "OpenCue.app" 180 170 \
  --hide-extension "OpenCue.app" \
  --app-drop-link 480 170 \
  --background-color "#ffffff" \
  ./build/OpenCue.dmg \
  ./build/export/OpenCue.app
```

**Option B: Using hdiutil (simpler, built-in)**

```bash
# Create temporary directory
mkdir -p ./build/dmg-content
cp -R ./build/export/OpenCue.app ./build/dmg-content/
ln -s /Applications ./build/dmg-content/Applications

# Create DMG
hdiutil create -volname "OpenCue" \
  -srcfolder ./build/dmg-content \
  -ov -format UDZO \
  ./build/OpenCue.dmg

# Clean up
rm -rf ./build/dmg-content
```

### 7. Notarize the DMG (optional but recommended)

```bash
xcrun notarytool submit ./build/OpenCue.dmg \
  --apple-id "USER_APPLE_ID" \
  --team-id "TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD" \
  --wait

xcrun stapler staple ./build/OpenCue.dmg
```

### 8. Verification

Test on a clean Mac (or a different user account):

```bash
# Verify code signing
codesign -dv --verbose=4 ./build/export/OpenCue.app

# Verify notarization
spctl -a -vvv ./build/export/OpenCue.app
# Should output: "source=Notarized Developer ID"

# Verify DMG
spctl -a -vvv --type open ./build/OpenCue.dmg
```

## What You Must NOT Do

- Do NOT modify any app source code — the app is done
- Do NOT change bundle identifier, app name, or version without asking the user
- Do NOT commit signing credentials, passwords, or certificates to the repo
- Do NOT use Mac App Store signing — this is Developer ID distribution only

## Output

When complete, provide the user with:
1. Path to the final `.dmg` file
2. Notarization status (success or what failed)
3. Any credentials or configuration the user needs to set up for future builds
4. A brief `doc/distribution-guide.md` with the steps automated as a build script

## Acceptance Checklist

- [ ] Xcode project has correct signing configuration (Developer ID Application)
- [ ] Hardened Runtime is enabled
- [ ] Entitlements file exists with appropriate entries
- [ ] App archives successfully
- [ ] App exports with Developer ID method
- [ ] App is submitted to Apple notarization service
- [ ] Notarization succeeds (no issues in log)
- [ ] Notarization ticket is stapled to the app
- [ ] DMG is created with app + Applications shortcut
- [ ] DMG opens cleanly with drag-to-install layout
- [ ] App launches from DMG without Gatekeeper warnings
- [ ] App launches from /Applications without Gatekeeper warnings
- [ ] `spctl` reports "Notarized Developer ID"
- [ ] App icon appears correctly in DMG, Finder, and Dock

## If Signing Credentials Are Missing

If the user hasn't set up Developer ID signing yet, create a document at `doc/signing-setup.md` with these instructions:

1. Enroll in Apple Developer Program ($99/year) at developer.apple.com
2. In Xcode → Settings → Accounts → add Apple ID
3. In Certificates, Identifiers & Profiles → create "Developer ID Application" certificate
4. Download and install the certificate
5. Create an app-specific password at appleid.apple.com for notarization
6. Store the credentials securely (Keychain, not in code)

Then STOP and tell the user to complete the setup before running this agent again.
