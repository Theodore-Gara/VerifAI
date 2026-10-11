# Codemagic Android Signing

The `manual_android_release` workflow creates a release-signed APK for
controlled testing. It reads the signing key from Codemagic secure environment
variables and does not store a keystore or passwords in this repository.
Treat the signing key as a credential: keep its backup offline and restrict
access to the Codemagic environment group. Do not use a test key for a Play
Store release.

## Create a signing key

Generate a dedicated test-distribution keystore outside the repository. Keep
the passwords private and retain a secure backup:

```sh
keytool -genkeypair -v \
  -keystore verifai-test-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias verifai-test
```

For Firebase Google Sign-In, register the certificate fingerprints for
`com.verifai.app`. Print them with:

```sh
keytool -list -v -keystore verifai-test-release.jks -alias verifai-test
```

Add the SHA-1 and SHA-256 fingerprints in Firebase Console under
**Project settings → General → Your apps → Android app**. Replace
`mobile/android/app/google-services.json` if Firebase provides an updated file.

## Configure Codemagic

Create an environment group named `verifai_android_signing` and attach it to
the `manual_android_release` workflow. Add these variables and mark each as
**Secure**:

| Variable | Value |
|---|---|
| `VERIFAI_RELEASE_KEYSTORE_BASE64` | Base64-encoded contents of `verifai-test-release.jks` |
| `VERIFAI_RELEASE_STORE_PASSWORD` | Keystore password |
| `VERIFAI_RELEASE_KEY_PASSWORD` | Key password |
| `VERIFAI_RELEASE_KEY_ALIAS` | `verifai-test` (or the alias chosen above) |

Encode the keystore locally without adding the encoded output to the repo. On
PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secure\verifai-test-release.jks"))
```

On macOS or Linux:

```sh
base64 < /secure/path/verifai-test-release.jks | tr -d '\n'
```

Paste the output directly into the secure Codemagic variable. Do not commit the
keystore, encoded keystore, or passwords.

## Run a build

In Codemagic, start a manual build using the `manual_android_release` workflow.
The resulting artifact is
`mobile/build/app/outputs/flutter-apk/app-release.apk`.

The workflow writes the keystore to `mobile/android/app` and the ignored
`mobile/android/key.properties` file, then runs `flutter build apk --release`.
Local and GitHub Actions builds without that file continue to use the Android
debug signing configuration; those APKs are for development/testing only.
Installing APKs signed with different keys requires uninstalling the existing
app first.

For a production Play Store release, create and maintain a separate production
signing setup and follow Google Play App Signing guidance. Do not distribute a
production app signed with a test key.
