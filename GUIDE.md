# Neon Shatter – install & publish guide

**What's in this folder:** the complete game (`www/index.html`, unchanged gameplay/features), app icons & splash (`assets/`), a Capacitor 8 wrapper config (`package.json`, `capacitor.config.json`), patch scripts (`scripts/`), and a GitHub Actions workflow (`.github/workflows/build-android.yml`) that builds the **APK and AAB in the cloud**.

> **Honest limitation:** the environment I worked in had no Android SDK, no Gradle/JDK compiler, no Xcode and no internet, so I could not compile the APK/AAB/iOS app myself. Everything *around* the build is done and checked (game tested in Chromium at phone size with touch input, saves persist across reloads, JSON/YAML/shell validated). The three paths below get you a real APK/AAB with no coding.

---
## A. Fastest: install it right now as an app (PWA, no APK)
1. Upload the **`www`** folder to any free HTTPS host (Netlify Drop: drag the folder onto app.netlify.com/drop; or GitHub Pages / Cloudflare Pages).
2. **Android (Chrome):** open the link → menu ⋮ → *Install app*. **iPhone (Safari):** Share → *Add to Home Screen*.
3. It opens full-screen, portrait, works offline after the first load, and saves progress on the device.

## B. Get the APK + AAB with no tools (GitHub Actions, ~10 min)
1. Create a free GitHub account and a **new private repository**. Upload the *contents* of this folder (including the hidden `.github` folder – use "Add file → Upload files" or `git push`).
2. Open the repo → **Actions** → *Build Android (APK + AAB)* → **Run workflow**.
3. When it finishes (green ✔), open the run → **Artifacts → neon-shatter-apk (and neon-shatter-aab)** → download. It contains:
   - `app-debug.apk` – **installable on your phone immediately** (debug-signed).
   - `app-release.aab` – Play Store bundle (**needs signing, see D3**; unsigned until you add the keystore secrets).
4. An optional, separate workflow (`build-ios-check.yml`) compiles an unsigned iOS simulator build on a Mac runner as a smoke test.

## C. Build locally (Windows/Mac/Linux)
Install: Node 22+, Android Studio (includes JDK 21 + SDK 36).
```bash
npm install
npm run android:add        # creates ./android, locks portrait, adds signing, generates icons/splash
npm run build:apk          # → android/app/build/outputs/apk/debug/app-debug.apk
npm run build:aab          # → android/app/build/outputs/bundle/release/app-release.aab (needs keystore env vars, D3)
npx cap open android       # or open ./android in Android Studio and press Run
```

---
## D. Install the APK on your Android phone
1. Copy/download `app-debug.apk` to the phone (Drive, USB, email, Telegram…).
2. Tap it. If asked, allow **"Install unknown apps"** for the app you opened it from (Settings → Apps → special access).
3. If Play Protect warns about an unrecognised developer, choose *Install anyway* (normal for non-Play builds).
4. Open **Neon Shatter**. It is portrait-locked; progress saves automatically (and when you background the app).
*(USB alternative: enable Developer options → USB debugging, then `adb install app-debug.apk`.)*

## D3. Make a store-ready signed AAB
1. **Pick your final package name now** – `appId` in `capacitor.config.json` (placeholder: `com.neonshatter.game`). It must be globally unique and **can never change after publishing**.
2. Create your upload key once and keep it + passwords safe (lose it = painful recovery):
```bash
keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 upload.jks > keystore.b64      # macOS: base64 -i upload.jks -o keystore.b64
```
3. In GitHub: Settings → Secrets and variables → Actions → add `KEYSTORE_B64` (contents of keystore.b64), `KEYSTORE_PASSWORD`, `KEY_ALIAS` (=upload), `KEY_PASSWORD`. Re-run the workflow → the `.aab` is now signed. (Locally: export the same four names plus `KEYSTORE_PATH=/path/upload.jks`.)
4. `versionCode` auto-increments from the GitHub run number; bump `versionName` in `android/app/build.gradle` for user-visible versions.

## E. Publish on Google Play
1. Create a **Google Play Console** developer account (one-time US$25, identity verification). *New personal accounts have had to run a closed test with a minimum number of testers for a set period before production – check Play Console's current requirement.*
2. *Create app* → name **Neon Shatter**, Game, Free. Enrol in **Play App Signing** (default) and upload the signed `.aab` to **Internal testing** first; install via the opt-in link and test.
3. Complete the checklist: store listing (short/full description, 512×512 icon = `www/icons/icon-512.png`, 1024×500 feature graphic, 2–8 phone screenshots – take them from your phone), **content rating** questionnaire, **Data safety** form (the game collects nothing and stores progress only on-device; update this if you add ads/analytics), **target audience** (if you target children, the Families policy applies – keep ads child-safe), and a **privacy policy URL** (required).
4. Promote to **Production** → send for review (first review can take several days).
5. Target API: Capacitor 8 targets Android 16 / SDK 36, which satisfies Google's yearly target-API rule; update Capacitor yearly to stay compliant.

## F. iOS / iPhone (needs a Mac + Apple Developer account, US$99/yr)
Apple only allows iOS builds from macOS/Xcode (Xcode 26+ for Capacitor 8).
```bash
npm install
npm run ios:add                  # creates ./ios, locks portrait, hides status bar, generates icons/splash
npx cap open ios                 # opens Xcode
```
In Xcode: select target **App** → *Signing & Capabilities* → choose your **Team**, set the **Bundle Identifier** (same as `appId`), version/build numbers → choose **Any iOS Device** → *Product → Archive* → *Distribute App → App Store Connect → Upload*.
Then in **App Store Connect**: create the app (same bundle ID), add it to **TestFlight** and test on your iPhone, fill in listing, screenshots (6.9" iPhone required), **age rating**, **App Privacy** labels, privacy-policy URL, then *Submit for Review*.
*No Mac?* Use a cloud Mac (e.g. Codemagic, or GitHub `macos-latest` with App Store Connect API key + signing certs) – the separate `build-ios-check.yml` workflow is the starting point.

## G. Notes
- **Fonts:** Orbitron/Rajdhani load from Google Fonts when online and fall back to system fonts offline. For a store release you may self-host them (download the `.woff2` files into `www/fonts/` and add `@font-face`).
- **Ads / purchases later:** the game already has `Ads.rewarded()` and `IAP` stubs in `www/index.html`. Replace the stub body with a real SDK call (e.g. Capacitor AdMob plugin, RevenueCat/Play Billing for cosmetic skins). Gameplay never depends on them.
- **Updating the game:** edit `www/index.html`, run `npx cap sync`, rebuild, bump version.
- **Saves:** stored in the WebView's `localStorage` (survives app restarts and updates; cleared if the user uninstalls or clears app data).
