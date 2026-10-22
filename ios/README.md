# Study Tracker — iOS Picture-in-Picture foundation

This experimental branch is isolated from `main`. It does not change the existing live website or Android project.

## iOS plan

1. Package the existing Study Tracker HTML experience with Capacitor iOS, maintaining existing styles and light/dark theme behavior.
2. Bridge timer state to native Swift, storing a deadline timestamp rather than trusting JavaScript background intervals.
3. Prototype `AVPictureInPictureController` using a supported AVKit media pipeline, with capability and runtime readiness checks.
4. Display remaining time and session type with a native PiP-compatible presentation; keep custom interactive menus in the full app because iOS owns PiP controls.
5. Persist study/break transitions and schedule permission-based local completion notifications. Test in background, after lock, and after app termination.
6. Validate on physical iPhones and iPads and assess whether timer-only PiP use complies with Apple App Review rules. PiP cannot be guaranteed for general-purpose timer overlays.
7. Keep web deployment and Android builds untouched; use separate iOS signing and TestFlight distribution.

## Build environment

Mac + Xcode, Node.js, Capacitor iOS, CocoaPods or Swift Package support as required, and Apple signing / TestFlight credentials.

## Acceptance criteria

- Existing website, theme options and Android build unchanged.
- Native iOS application compiles and displays the existing timer interface.
- Countdown resumes with accurate time after app switching.
- PiP is enabled only when OS reports supported and permitted; show graceful fallback otherwise.
- Local notifications require user permission.
- PiP behavior and App Review eligibility validated before claiming production support.
