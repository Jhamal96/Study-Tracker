# Study Timer — Android application

This native Android WebView shell opens https://studytimer.ajdapp.org and preserves the existing website design, settings, authentication and Cloudflare hosting. A small native PiP view reads `study-tracker-clock` from the site localStorage and shows the running study/break time when the app moves to Android Picture-in-Picture on supported devices. Native PiP requires user/OS permissions and is distinct from browser Document PiP.

**Build:** GitHub Actions workflow [Android APK](https://github.com/Jhamal96/Study-Tracker/actions/workflows/android-apk.yml); asset name `Study-Timer-Android.apk`, saved as a workflow artifact and published to the `android-latest` release. The website's /download page links to that asset.

**Local build:** open `android/` in Android Studio (JDK 17, Android SDK 35, Gradle 8.9), then build `:app:assembleDebug`.

**Distribution limitations:** This is an unsigned-for-release *debug* APK, not a Play Store package. Builds on different GitHub runners may have different debug signing keys. An existing install may reject an update due to signature mismatch; uninstalling first erases local WebView storage, so sync/back up personal settings beforehand. For production, configure a stable release keystore as GitHub encrypted secrets and use `:app:assembleRelease`. GitHub is private, so release assets require authorized GitHub access. External sign-in/auth flows may require additional native integration.

**Security:** WebView top-level navigation is restricted to the HTTPS site and opens other HTTPS links using the system browser. Web content runs without a native JavaScript bridge. Local and cloud user data are not embedded in the APK.
