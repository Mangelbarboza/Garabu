# Garabu — Android / Google Play

- Package: `com.garabu.app`
- Version: `1.0.0+1`
- Minimum Android API: 24; target API: 36.
- Privacy and account deletion: https://mangelbarboza.github.io/Garabu/
- Support: Angelbarbozareyes29@gmail.com
- Free, no advertising, no real-money purchases; intended audience 16+.

## Private signing setup

Keep the upload keystore and passwords outside version control. Configure the ignored `android/key.properties`:

```properties
storeFile=C:/private/garabu-upload.jks
storePassword=YOUR_PRIVATE_PASSWORD
keyPassword=YOUR_PRIVATE_PASSWORD
keyAlias=garabu-upload
```

Release tasks fail if signing configuration is missing; debug builds do not require this private file.

## Build

Run `flutter pub get`, then `flutter build appbundle --release`. Install the Android SDK components requested by Gradle using the Android SDK manager.

If API 36 is installed and older Firebase libraries request an unavailable API 34 package, the included initialization script compiles Android libraries against API 36. From `android/`, after dependencies are resolved:

```powershell
./gradlew.bat -I play-release.init.gradle bundleRelease -Ptarget=lib/main.dart -Ptarget-platform=android-arm,android-arm64,android-x64 -Ptree-shake-icons=true
```

The resulting bundle is `build/app/outputs/bundle/release/app-release.aab`.

## Validation and limits

- Existing Flutter test suite: 23 tests passed.
- Analysis of modified Dart files passed.
- The Android Firebase app ID matches the `com.garabu.app` client in `google-services.json`.
- Reviewer email/password accounts were created and paired through the actual app UI. Their credentials belong only in Play Console and private local files.
- Native Android Google sign-in has not been device-tested. Validate it and the Play app-signing certificate configuration in Firebase before a public release; reviewers use email/password.
- Account deletion now surfaces errors and requests a recent login instead of silently reporting success. Shared room content is not automatically deleted when the profile is removed; privacy instructions describe the email request path.
- Blocking, reporting and moderation of user content are absent in the current game. Review the applicable user-generated-content requirements before expanding beyond internal testing.
- Firebase server security rules were not available in this repository and have not been audited.

## Data declarations

The declaration covers profile name, email, Firebase user ID, optional age, optional in-app letters, gameplay interactions, drawings and other created content, and Firebase technical metadata/identifiers. Firebase service-provider transfers and deliberate sharing with the linked partner are described in the privacy policy. No advertising ID permission is present in the merged release manifest.

Sources for SDK disclosure and deletion requirements:

- https://firebase.google.com/docs/android/play-data-disclosure
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/13327111
