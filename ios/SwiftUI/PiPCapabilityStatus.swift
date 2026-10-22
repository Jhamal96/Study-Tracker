import SwiftUI
import AVKit

/// Capability check only. It does NOT start PiP or claim a timer-only overlay is eligible.
struct PiPCapabilityStatus: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Picture in Picture", systemImage: "pip")
                .font(.headline)

            if AVPictureInPictureController.isPictureInPictureSupported() {
                Label("Device supports PiP", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                Text("A supported, active media content source and playback delegate are still required. Native timer-only PiP is experimental and may not qualify for App Review.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Label("PiP is unavailable on this device", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
                Text("The full-screen timer remains available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
