# Native Apple PiP prototype — Study Timer and Break Tracker

The iPad recording showed the installed website's **in-page mini timer**, which disappears on the Home Screen. A Home Screen website installation is not a native AVKit app.

This folder builds two native iPhone/iPad applications with the existing hosted interfaces, a visible native timer preview, and an `AVSampleBufferDisplayLayer` / `AVPictureInPictureController` countdown. No camera, microphone, silent audio file, private API, or new server/database access is used. The media audio session is active while a running timer is armed for automatic PiP, while a manual start is pending, or while PiP is active; it is released when those uses end.

**Status: experimental.** CI compiles both simulator apps and tests timestamp/auto-start calculations. Simulator compilation does not prove Home Screen PiP works on a physical iPad. Do not advertise this as a working iPad download until a signed build has been installed and the device checklist below passes. App Store/TestFlight review acceptance is not established.

## Build and install

On a Mac with a current Xcode and XcodeGen:

1. `cd ios && xcodegen generate`
2. Open `AJDNativeTimers.xcodeproj` in Xcode.
3. Select `StudyTimerApple` or `BreakTrackerApple`, choose your Apple development team, and connect your iPhone/iPad.
4. Run on that device. For TestFlight, configure distribution signing and App Store Connect for each bundle identifier before archiving/uploading.

CI's unsigned `.app` artifacts run in a simulator; they cannot be installed on a physical iPad. Creating an unsigned IPA would not remove the signing requirement. XcodeGen-generated project/build output is not committed.

Each native app has its own WebKit data store. Existing Home Screen website local data is not automatically copied into it. Sign in to existing cloud sync where available. Kitt-only local schedules need to be entered in the new app; the old installed website and its records are left intact.

## Behavior and limits

- **PiP on Home Screen** is on by default in each native app and remembers your choice. With an active countdown, the app prepares its media session in the foreground and enables AVKit's automatic inline PiP. Go to the Home Screen or another app; iOS decides whether to start PiP. This still requires a real-device test and is not an HTML/PWA update.
- Turn that switch off to use only the website's existing PiP button or the native **Float Timer** button after starting a countdown. Automatic and manual entry use the same native renderer.
- Idle, paused, and finished countdowns do not arm automatic PiP. Study auto-start phases remain eligible while their countdown continues. Closing PiP suppresses automatic re-entry until you return to the app or start a new countdown; turning the setting off releases its unused media session.
- The preview must remain attached and visible while AVKit prepares PiP. Start/stop success and failures appear as persistent native status messages.
- Web messages are accepted only from the configured HTTPS host and main frame. External HTTPS destinations open outside the bridged WebView.
- The native countdown uses the same absolute finish time, not an independently decrementing counter. Study auto-start phases are calculated natively if WebKit pauses. On returning, the website reconciles its own saved deadline as before.
- Timer changes, including pause/reset, are made in the tracker. System media controls do not pause a wall-clock deadline. Native PiP does not currently render the web's selectable styles/quotes or provide background completion notifications/chimes.
- Kitt PiP displays the first currently active vehicle, matching the website's floating timer selection.
- Only PiP is being enabled. This does not claim uninterrupted background execution after the PiP window is closed, screen-lock display, a Lock Screen widget, or a Live Activity.

## Physical iPad/iPhone acceptance checklist

1. Leave **PiP on Home Screen** on, set a 1-minute timer, and go directly to Home without tapping Float Timer. Verify native PiP appears, remains visible in another app, and counts down correctly. Repeat with the switch off: Home must not open PiP; Float Timer must still work. Check paused, reset, and finished timers do not open PiP automatically, and verify the switch persists after relaunch.
2. Close PiP; return to tracker and verify the timer remains correct. Repeat open/close and rotate the device.
3. Test a study-to-break auto transition and a paused/reset timer, then return to the main app; compare phase, finish time and daily counts.
4. For Break Tracker test MA/ZIP, lunch, custom break and Kitt; verify cloud records are not changed just by opening/closing PiP.
5. Test disabled PiP permission, offline launch, account sign-in/out and external links. Confirm failures are shown without opening an in-page panel as if it were system PiP.

Apple API reference: https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/contentsource-swift.class/init(samplebufferdisplaylayer:playbackdelegate:)

