import SwiftUI

@main
struct TimerApp: App {
    var body: some Scene {
        WindowGroup { TimerContainer().ignoresSafeArea(edges: .bottom) }
    }
}

/// UIKit is needed for the sample-buffer PiP content source and WKWebView bridge.
struct TimerContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TimerViewController { TimerViewController() }
    func updateUIViewController(_ controller: TimerViewController, context: Context) {}
}
