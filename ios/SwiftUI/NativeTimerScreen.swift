import SwiftUI

struct NativeTimerScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = NativeTimerSession()
    @State private var workMinutes = 25
    @State private var restMinutes = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(session.phase.label)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TimerCountdown(session: session)
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

                    HStack {
                        Button(session.isRunning ? "Pause" : "Start") {
                            if session.isRunning { session.pause() }
                            else { session.start() }
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(session.isRunning ? "Pause countdown" : "Start countdown")

                        Button("Reset") { session.reset() }
                            .buttonStyle(.bordered)

                        Button("Next") { session.changePhase(to: session.phase.next) }
                            .buttonStyle(.bordered)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Automatically start next session", isOn: $session.autoAdvance)
                            .onChange(of: session.autoAdvance) { _, _ in session.reset() }

                        Stepper("Focus / work: \(workMinutes) min", value: $workMinutes, in: 1...240)
                        Stepper("Break: \(restMinutes) min", value: $restMinutes, in: 1...120)
                        Button("Apply durations") {
                            session.setDurations(workMinutes: workMinutes, restMinutes: restMinutes)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

                    PiPCapabilityStatus()
                }
                .padding()
            }
            .navigationTitle("Study Timer")
            .task {
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(1)) }
                    catch { break }
                    session.reconcile()
                }
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active { session.reconcile() }
            }
        }
    }
}

/// Isolated 1 Hz invalidation boundary, avoiding updates to the entire screen.
private struct TimerCountdown: View {
    let session: NativeTimerSession

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int(ceil(session.remaining(at: context.date)))
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityLabel("Time remaining")
                .accessibilityValue("\(remaining / 60) minutes, \(remaining % 60) seconds")
        }
    }
}

#Preview {
    NativeTimerScreen()
}
