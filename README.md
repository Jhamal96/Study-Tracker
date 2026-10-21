# Study Tracker 🌷

A sweet, minimal study + break interval timer, made for Whitney.

## Features
- Adjustable study minutes (1–240), break minutes (1–120), and study rounds (1–20)
- Start, pause, reset, skip, and automatic study/break cycling
- Gentle chime and study/break browser notifications, with an enable/disable control and live **Send a test notification** button in Settings
- Notification display uses the service worker first (with browser Notification fallback) and can open/focus the Study Tracker website when tapped
- The three former homepage options—Browser Reminders, Welcome pop-up, How it works pop-up—are in the Settings modal; the Cloud Sync button and account controls are also accessible from Settings
- Two independent, always-visible home-page quote cards: a rotating motivational message and a rotating Gospel passage from the King James Version with Bible reference
- Welcome pop-up showing both messages side by side in separate sections, including a “Don't show this again” option
- How Study Tracker Works introductory pop-up appears above the quote pop-up on opening, explains study/break timings, auto-start, round goals, chimes, floating timer, and cloud sync
- Independent "Don't show this again" controls for the guide and the quote pop-up, each re-enabled independently from Settings
- Quotes refresh separately on each page open, even when the pop-up is disabled; the pop-up can be turned on again in settings
- Rose, lavender, and sage color themes
- Automatically follows the device's light/dark appearance and changes live with system settings, including welcome pop-ups, settings panel, and both floating/Picture-in-Picture timer styles (pastel accent choice remains saved)
- Six floating timer display options: **Dial** (default circular progress ring), **Digital** (large countdown and progress bar), **Minimal** (clean countdown), **Clock** (analog clock face), **Speedometer** (semicircular gauge), and **Wavy Ring** (a soft circular track with a growing wavy elapsed-time arc and clear remaining-time labels, inspired by a reference screenshot). Change styles in **Settings → Floating timer**, in a supported Document Picture-in-Picture window, or in the in-page floating timer. Video Picture-in-Picture also draws the chosen style but has no in-window style controls. Style selection is saved on this device; all styles honor the rose/lavender/sage theme and system dark/light mode.
- Keeps timing accurate across browser tabs or when the screen is locked; remaining time is saved on the same device
- Daily completed-study count, with customizable round goal
- PWA install support with custom flower icon and cached offline assets
- No account necessary; local settings are saved automatically
- Optional Supabase email sign-in to sync preferences between devices (cloud preferences use per-user Row Level Security)

## Hosting
- GitHub: standalone private repository `Jhamal96/Study-Tracker`, all app files located at repository root
- Cloudflare Pages: project `study-tracker`, production branch `main`, root directory `.`, output directory `.` and no build command
- Public website: https://study-tracker-cip.pages.dev/
- Supabase: existing shared Supabase project, with dedicated `public.study_tracker_preferences` table and owner-only RLS policies.

## Cloud email sign-in
The Supabase Auth URL Configuration needs `https://study-tracker-cip.pages.dev/**` added to its redirect allowlist in the dashboard for email magic-link sign-ins to return to this website. Local-only use does not need this.

## Files
- `index.html`: entire responsive application
- `icon.svg`: app and browser icon
- `manifest.webmanifest`: installable app metadata
- `sw.js`: offline cache and PWA service worker

Made with ♡


## Floating timer / Picture-in-Picture
Press the small overlapping-window icon beside **Next**:
- Compatible desktop browsers: opens a real always-on-top Picture-in-Picture window with a live timer, **Pause/Resume**, **Next**, and **Reset** controls.
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
