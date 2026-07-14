# Releasing Enercore

Everything in the code is ready to ship. What's left needs a human with a
credit card and a store account — that's listed under "Only you can do this".

---

## Facts you'll need

| | |
|---|---|
| Android package | `com.enercore.app` |
| iOS bundle ID | `com.enercore.app` |
| Display name | Enercore |
| Version | `1.0.0+1` (in `pubspec.yaml` — `versionName+versionCode`) |
| API | `https://enercore-api-11148.azurewebsites.net/api` |
| Keystore | `android/enercore-release.jks`, password in `android/key.properties` |
| Privacy policy | `docs/privacy.html` → publish via GitHub Pages (below) |
| Store assets | `store/` |

**Back up the keystore.** `android/enercore-release.jks` and its password are the
only way to ever ship an update. Lose them and you must publish a new app under a
new package name. They are gitignored on purpose — put them somewhere safe
(password manager / encrypted drive), not in the repo.

---

## Build the artefacts

The API URL is baked in at build time. **Without `--dart-define`, the app points
at `localhost` and will not work on anyone's phone.**

```bash
# Play Store (Android App Bundle)
flutter build appbundle --release \
  --dart-define=API_URL=https://enercore-api-11148.azurewebsites.net/api
# -> build/app/outputs/bundle/release/app-release.aab

# Sideload / direct install (APK)
flutter build apk --release \
  --dart-define=API_URL=https://enercore-api-11148.azurewebsites.net/api
```

**Test the release build on a real device before uploading.** The release build
is minified (R8), and minification can break things that only show up at runtime.
Debug builds do not exercise this.

For each release, bump `version:` in `pubspec.yaml` — Play rejects a bundle whose
`versionCode` it has already seen.

---

## Publish the privacy policy (required by both stores)

`docs/privacy.html` is written and ready. Give it a public URL:

1. Push to GitHub.
2. Repo → **Settings → Pages**.
3. Source: **Deploy from a branch**; branch `main`, folder **`/docs`**. Save.
4. In a minute the policy is live at:
   `https://ayuuu-tech.github.io/enercore/privacy.html`

Use that URL in both store listings. (If Enercore would rather host it on
`enercore.org`, that's fine too — just paste the same HTML there.)

---

## Google Play

**Only you can do this:** create a [Play Console](https://play.google.com/console)
account — **$25, one time**.

Then, in the Console:

1. **Create app** → name `Enercore`, type: App, free.
2. Upload `build/app/outputs/bundle/release/app-release.aab`
   (start in **Internal testing** — it's the fastest track and lets you install
   from the Play Store on your own phone before going public).
3. **Store listing:**
   - App icon → `store/play-icon-512.png`
   - Feature graphic → `store/feature-graphic-1024x500.png`
   - Phone screenshots → **at least 2** (take these from a real device: open the
     app, screenshot Home, Solar Grid, Telemetry, Billing)
   - Short + full description → copy from below
4. **Privacy policy** → the GitHub Pages URL.
5. **Data safety form.** Declare honestly, matching `docs/privacy.html`:
   - Collected: Name, Email address, Phone number, Address, Photos (optional
     avatar), User support messages, App activity.
   - Data is **encrypted in transit** ✅
   - Users **can request deletion** ✅
   - Data is **not** shared with third parties, **not** used for ads,
     **no** tracking. Location is **not** collected.
6. **Content rating** questionnaire → it's a business/productivity app, no
   objectionable content.
7. **Target audience:** 18+ / business. Not for children.
8. Submit. First review typically takes a few days.

### Suggested listing copy

> **Short description (80 chars max)**
> Live monitoring, performance and billing for your Enercore solar plants.

> **Full description**
> Enercore gives you a live view of the solar plants Enercore operates for you.
>
> • **Live generation** — current power, today's yield and lifetime output for
>   every site, refreshed continuously.
> • **Plant health** — per-inverter status, voltage, current and frequency, so
>   you can see a problem before it costs you a day's generation.
> • **Performance** — daily, weekly, monthly and yearly generation, and how each
>   site compares against its capacity.
> • **Billing** — your monthly solar bill of supply, with the meter readings it
>   was raised on, downloadable as a PDF.
> • **Support** — raise a ticket against a specific plant and track it to
>   resolution.
>
> Enercore is for existing Enercore customers. Your account is created for you —
> please contact sales@enercore.org if you need access.

---

## Apple App Store

**Two things block this, and neither is code:**

1. **Apple Developer Program — $99/year.** No way around it.
2. **You cannot build an iOS app on Linux.** Apple requires macOS + Xcode. Your
   options:
   - a Mac (borrowed is fine — it's a one-command build), or
   - a cloud macOS runner. CI already builds iOS on `macos-latest` on every push,
     so you know it *compiles*; producing a **signed** `.ipa` additionally needs
     your Apple certificates loaded into the runner (Codemagic and GitHub Actions
     both support this).

The code side is done: bundle ID is `com.enercore.app`, the app is named
Enercore, and it enforces HTTPS (no ATS exceptions).

Once you have the account and a Mac/runner:

```bash
flutter build ipa --release \
  --dart-define=API_URL=https://enercore-api-11148.azurewebsites.net/api
```

Then upload via Xcode Organizer or Transporter, and fill in App Store Connect
(same privacy policy URL, same screenshots, plus Apple's privacy "nutrition
labels" — the answers are the same as Play's data safety form above).

---

## Only you can do this

- [ ] Play Console account ($25)
- [ ] Apple Developer account ($99/yr) — iOS only
- [ ] Enable GitHub Pages for the privacy policy
- [ ] Take phone screenshots from a real device
- [ ] Back up the keystore + password somewhere safe
- [ ] Test the release build on a real phone
- [ ] Fill the data safety / privacy forms and hit Submit

## Watch out for

- **Azure credit.** The backend runs on a B1 App Service plan on an Azure for
  Students subscription. When that credit runs out, the API stops — and so does
  every phone running this app, plus the telemetry collection behind your bills.
  Move it to a paid subscription before you have real users depending on it.
