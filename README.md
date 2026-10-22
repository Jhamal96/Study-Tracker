# Study Tracker 🌷

A sweet, minimal study + break interval timer, made for Whitney.

## Features
- Adjustable study minutes (1–240), break minutes (1–120), and study rounds (1–20)
- A compact **Custom** sliders icon beside the **Break Time** tab (with a hover/focus tooltip) opens the **Make it your own** dialog. This replaces the old sidebar customization card while retaining all six +/- controls, number inputs, automatic saving and secure optional cloud synchronization.
- Start, pause, reset, skip, and **automatic study → break → study** cycling (enabled by default for new and existing visitors). Round-goal celebrations do not interrupt auto-cycling, and time missed while tabs are suspended is reconciled from stored timestamps.
- Configurable, gently synthesized completion sounds: **Music box, Soft bells, Dreamy harp, Wind chimes, Cozy piano, Morning birds**. Choose **1, 2, 3, 5, or 8 seconds**, hear a preview, or turn chimes off. Preview works with automatic completion sound disabled.
- Gentle chime and study/break browser notifications, with an enable/disable control and live **Send a test notification** button in Settings
- Notification display uses the service worker first (with browser Notification fallback) and can open/focus the Study Tracker website when tapped
- The three former homepage options—Browser Reminders, Welcome pop-up, How it works pop-up—are in the Settings modal; the Cloud Sync button and account controls are also accessible from Settings
- **What's New** opens automatically for a new release and stops appearing after the visitor taps **Got it!**. The **Settings → Updates** tab keeps a permanent, readable list of improvements and can reopen the announcement at any time.
- **Auto-start next timer**, **Gentle chime enable**, **Sound selection / duration / preview**, and **Color mood** are all available inside **Settings**; the study, break and round lengths have moved into the **Custom** pop-up beside Break Time.
- Two independent, always-visible quote cards—motivational and Gospel/KJV—now appear **above the main timer**, and condensed versions remain **above the floating timer** in Document PiP, video PiP, and the in-page floating fallback.
- Welcome pop-up showing both messages side by side in separate sections, including a “Don't show this again” option
- How Study Tracker Works introductory pop-up appears above the quote pop-up on opening, explains study/break timings, auto-start, round goals, chimes, floating timer, and cloud sync
- Independent "Don't show this again" controls for the guide and the quote pop-up, each re-enabled independently from Settings
- Quotes refresh separately on each page open, even when the pop-up is disabled; the pop-up can be turned on again in settings
- **Nine color themes**: Rose, Lavender, Sage, Peach, Sky, Mint, Buttercream, Lilac, and Coral. Theme selection follows light/dark appearance in both main and floating timers.
- Automatically follows the device's light/dark appearance and changes live with system settings, including welcome pop-ups, settings panel, and both floating/Picture-in-Picture timer styles (pastel accent choice remains saved)
- **10 cute Picture-in-Picture timer styles:** Bloom Circle, Wavy Love, Sweet Hearts, Stardust, Cloud Nine, Pastel Rainbow, Butterfly, Boba Bubbles, Candy Pop, and Cozy Cup. These replace the older six-style clock selector; there are no longer separate Clock or Speedometer options.
- **Hamburger menu (☰) inside interactive Document PiP and the in-page floating timer** contains the 10 styles; the distracting row of PiP style buttons is removed. Switch looks while the timer runs, without losing countdown progress. Style choice is saved to this device.
- **Settings → Floating timer → ☰ Choose from 10 cute timer styles** provides the same picker for all devices. In browsers that offer video-only PiP, the video countdown follows this setting but cannot show an interactive hamburger menu inside the video.
- All ten designs respect rose/lavender/sage accent themes, light/dark appearance, study/break labels and timer progress.
- Keeps timing accurate across browser tabs or when the screen is locked; remaining time is saved on the same device
- Daily completed-study count, with customizable round goal
- PWA install support with custom flower icon and cached offline assets
- No account necessary; local settings are saved automatically
- **Cloud Sync now has Sign Up and Sign In tabs** with email/password authentication, confirmation-password checks, password recovery, and a retained **email sign-in link** option for existing accounts. Signed-in email-link users can set or change a password without creating a separate account. Supabase manages passwords; private preferences remain protected by per-user Row Level Security.

## Hosting
- GitHub: standalone private repository `Jhamal96/Study-Tracker`, all app files located at repository root
- Cloudflare Pages: project `study-tracker`, production branch `main`, root directory `.`, output directory `.` and no build command
- Main custom domain: https://studytimer.ajdapp.org/ (Cloudflare Pages custom domain **active**, SSL validation active, and proxied CNAME confirmed)
- Original Pages address remains available: https://study-tracker-cip.pages.dev/
- Supabase: existing shared Supabase project, with dedicated `public.study_tracker_preferences` table and owner-only RLS policies.

## Cloud account access
Open **Settings → Cloud Sync** to get two clear options:
- **Sign Up:** enter an email, create a password of eight or more characters, confirm it, and check email for verification if required by Supabase Auth.
- **Sign In:** use your registered email and password. For the previous passwordless experience, select **Email me a sign-in link instead**.
- **Forgot password?:** request a recovery email, then choose a new password using the secure link. Existing email-link users can also sign in using their usual email link and choose **Set or change password**; their account and saved preferences remain the same.
- **Sign Out:** ends the session. No password is stored in the website's localStorage or cloud-preferences table; Supabase Auth handles credentials.

This change only updates the website's account UI and Auth API calls. No new public database table or relaxed RLS policy was required. Password registration depends on the email provider/sign-up options in Supabase Authentication → Providers. Confirmation/reset/OTP links need the custom and original Pages URLs allowed under Authentication → URL Configuration.

## Cloud email sign-in
The Supabase Auth URL Configuration needs `https://study-tracker-cip.pages.dev/**` and `https://studytimer.ajdapp.org/**` added to its redirect allowlist in the dashboard for email magic-link sign-ins to return to this website. Local-only use does not need this.

## Files
- `index.html`: entire responsive application
- `icon.svg`: app and browser icon
- `manifest.webmanifest`: installable app metadata
- `sw.js`: offline cache and PWA service worker

Made with ♡


## Floating timer / Picture-in-Picture
Press the small overlapping-window icon beside **Next**:
- Compatible desktop browsers: opens a real always-on-top Picture-in-Picture window with a live timer, **Pause/Resume**, **Next**, **Reset**, and a **☰ hamburger menu** for the ten designs.
- Where only video Picture-in-Picture is supported: opens a styled floating video countdown. Use the main tab to change or pause the timer.
- If the browser blocks both PiP methods: opens a small draggable timer inside the Study Tracker page, with **Pause/Resume**, **Next**, and **View**. This in-page fallback does not appear over other apps.
- On some phones and in installed web apps, the operating system/browser may forbid floating the timer over the home screen or other apps. Genuine system-level Android overlay/PiP in those cases requires a separate native Android app.
- The browser must keep the site open. Timer durations are still calculated from timestamps rather than counting every interval tick.

## Important notification limitations
- On desktop, grant permission in the browser and in the operating system. Test the alert from **Settings → Alerts & reminders → Send a test notification**.
- On iPhone/iPad, website notifications are generally available only when the site is installed to the Home Screen and launched from its icon; the user must approve notifications in that installed app.
- Session-end reminders work while the Study Tracker page is running. If the browser or operating system fully suspends or closes the website, the timer may not fire until reopened. This version does **not** implement server-pushed notifications to closed browsers.
- If permission is denied or unsupported, the Settings panel explains what to do; the timer and the on-page transition messages continue working.

## Migration
- Standalone repository contains the current Study Tracker app. Cloudflare Pages `study-tracker` now connects to `Jhamal96/Study-Tracker` (`main`, project root `.`), retaining `https://study-tracker-cip.pages.dev/`.
- The old `Jhamal96/Test/study-tracker` folder is retained as a historical backup and is no longer Cloudflare's deployment source.

## Cloud-synced sound and color choices
The shared Supabase `public.study_tracker_preferences` table has an expanded nine-color theme constraint and owner-protected `chime_sound` and `chime_duration` columns. Legacy rows default to Music box and 3 seconds. These preferences sync with the signed-in account; sound playback still requires a browser/device allowing Web Audio.

## Publishing future changes and update notes
For every user-visible Study Tracker change, add a new entry to the front of `STUDY_RELEASES` in `index.html`. Give it a unique `id`, a readable release date/title, and concise `notes` explaining precisely what changed. The newest entry is shown in the update announcement and the Settings → Updates history.

The site compares the deployed `index.html` content fingerprint with the last acknowledged revision on each online opening. When the site changes but no new release note has been added, it still shows a general “new improvements” announcement rather than falsely claiming older changes are new. Acknowledgement is saved in localStorage for that browser/device and is only reset when the newest release ID or the deployed HTML changes. Visitors can always reopen earlier notes through Settings → Updates, including after acknowledging the pop-up. Offline launches use the embedded release ID without a network request succeeding.

To test a new update locally, clear only `study-tracker-acknowledged-update-v1` from localStorage (do not clear timer preferences), then reopen the site. Verify the introduction and quote pop-ups still work after the announcement is acknowledged.
