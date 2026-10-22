import SwiftUI

/// Experimental standalone entry point for a fresh Xcode iOS App target.
/// Do not add this @main file to an existing app target that already has one.
@main
struct NativeTimerApp: App {
    var body: some Scene {
        WindowGroup {
            NativeTimerScreen()
        }
    }
}
