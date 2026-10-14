# Neon Driftline Classic — Android release

## One banner, no interruptions

The *only* supported ad format is a **320×50dp banner anchored at the top**. It stays attached from app startup through gameplay, research, shop, pause, and results screens while a banner is available and Google User Messaging Platform consent permits ad requests. Android HUD and menu headers reserve 64 virtual pixels of clearance. No interstitial, rewarded, app-open, or video ads are implemented. Browser builds are ad-free.

The code loads Poing Studios Godot AdMob plugin v5.1.0 dynamically and requires Android; it intentionally fails open (no ad) when offline or lacking SDK/consent. Android developer builds use Google's test App ID `ca-app-pub-3940256099942544~3347511713` and test Banner Ad Unit `ca-app-pub-3940256099942544/6300978111`. These IDs cannot generate revenue.

## Build and install

The `.github/workflows/build-classic-android.yml` workflow installs matching Godot 4.7.2 editor/export templates, pinned Poing Android library, Android SDK 36, Gradle source build template, creates an original launcher icon, runs Godot smoke tests, and exports an installable **debug APK** under its Actions artifacts. Use `adb install -r neon-driftline-classic.apk` or sideload the extracted file on Android. No AdMob publishing account is needed to test with Google's sample IDs.

The Android export preset currently uses provisional package name `com.dmcexcess.neondriftline`. Confirm this identifier before first Play Console upload.

## Enable production banner ads

1. Register the app with Google AdMob. Configure its Privacy & Messaging consent messages, including applicable EEA/UK and US-state notices; verify with test devices.
2. Set `admob/general/android/app_id` in project settings to **your own** AdMob App ID (containing `~`). Set `neon/ads/banner_unit_id` to **your own banner ad unit** (containing `/`). Test with Google test IDs before requesting live ads. Never mix up app vs. ad unit IDs.
3. Update/store an accurate privacy policy and Play Console Data Safety/Ads declarations. If the app targets children, review the Google Play Families and AdMob policies before enabling ad requests. Confirm advertising SDK disclosures and any account-specific ad technology requirements.
4. On a physical Android device verify banner position on all screens, consent opt-out, ad failure fallback, orientation, controls, audio, app pause/resume and persistence.

## Store-ready signing and publication

For a signed release **Android App Bundle** (`.aab`), configure GitHub Action secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` with a *persistent* Play upload-signing keystore. Do not commit your keystore. Play App Signing handles production app distribution; export AAB for upload. Upload to an **internal testing** track, inspect device pre-launch reports, then progress through any required closed testing and production review.

Google Play's new app target requirement from August 31, 2026 is **Android 16 / API 36**. New personal developer accounts can be subject to closed testing with **12 testers opted in continuously for 14 days**. Production distribution needs an approved Play Console account, a store listing, content rating, privacy policy, app graphics, screenshots, Data Safety form, ads disclosure, and review approval.

This project cannot be claimed live on Google Play without verifying a real Play Console submission and release. The repository and Web deployment do not themselves publish to Google Play.

Official references: https://support.google.com/googleplay/android-developer/answer/11926878 ; https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html ; https://developers.google.com/admob/android/banner ; https://poingstudios.github.io/godot-admob-plugin/
