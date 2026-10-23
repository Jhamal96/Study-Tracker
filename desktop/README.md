# Study Timer — Desktop installers

The Windows and macOS apps wrap the existing production website at https://studytimer.ajdapp.org/. They do **not** replace the web app or Android project. App data follows the same server-side account and Supabase rules as the website; local webview storage is independent of browser storage.

- Windows: `Study-Timer-Windows-Setup.exe` (Windows x64)
- macOS: `Study-Timer-macOS.dmg` (universal Intel + Apple Silicon)
- Repository workflow: [Build Windows and Mac desktop installers](https://github.com/Jhamal96/Study-Tracker/actions/workflows/desktop.yml)
- Release assets: https://github.com/Jhamal96/Study-Tracker/releases/tag/desktop-latest
- Download website: https://studytimer.ajdapp.org/download

GitHub Actions runs when `desktop/**` or the desktop workflow changes or from the **Run workflow** button. Build results appear as workflow artifacts and a stable `desktop-latest` pre-release. Both installers are intentionally **unsigned** for initial testing: Windows SmartScreen and macOS Gatekeeper may show warnings, and macOS notarization requires an Apple Developer account. Do not disable system-wide security features to install.

The repository is currently **private**. Release downloads therefore require an authorized GitHub sign-in; a separate public distribution location is needed before inviting public visitors to download files.

The desktop shell uses Electron with Node integration disabled, context isolation and renderer sandbox enabled; external links open in the system browser. The hosted website must be online for full functionality and will supply UI updates immediately. Build and test an installer before distributing it widely.

## Local development

Run `cd desktop && npm install && npm start`. To make an installer on the matching OS, run `npm run dist:win` on Windows or `npm run dist:mac` on macOS.
