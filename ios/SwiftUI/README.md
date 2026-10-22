# Study Timer — SwiftUI experimental app

Native SwiftUI timer prototype for iOS 17+; generated with SwiftUI Expert guidance. All files live only on `feature/ios-pip-foundation`. Existing web UI, Cloudflare deployment and Android builds remain intact.

## Try in Xcode (Mac)

1. File → New → Project → iOS → App, SwiftUI, Swift. Choose deployment target iOS 17 or newer.
2. Remove the new template's generated app entry point and `ContentView.swift`, or exclude them from target membership. This folder's `NativeTimerApp.swift` is its own `@main` entry point.
3. Add the four `.swift` files from this folder to the app target.
4. Run on an iPhone or iPad. The native timer can start, pause, reset, auto-transition between work/breaks, and restore deadlines after leaving the app.
5. Confirm `PiPCapabilityStatus` shows device support. **It deliberately does not start PiP yet.** A separate media-layer experiment, hardware validation, and App Store policy review must come first.

## Engineering notes

- This is a standalone SwiftUI proof-of-concept, **not** yet connected to existing website settings/storage.
- Duration settings remain local to iOS, and no background audio hacks are used.
- The deadline-based countdown recovers correct remaining time on foreground, but background app execution is not guaranteed.
- A completion alert will require separate `UNUserNotificationCenter` integration and permission.
- To support the original HTML app in a native wrapper, use Capacitor or a WebKit integration as a separate next step.
- Apple's PiP API requires eligible media content: `AVPlayerLayer` or `AVSampleBufferDisplayLayer` (or an active video-call source). It is **not** a general always-on-top SwiftUI overlay.
