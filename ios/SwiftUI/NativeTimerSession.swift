import Foundation
import Observation

/// Independent native proof of concept; existing website/Android storage is untouched.
enum NativeTimerPhase: String, Codable, CaseIterable, Identifiable {
    case work
    case rest

    var id: String { rawValue }
    var label: String { self == .work ? "Focus / Work" : "Break" }
    var next: Self { self == .work ? .rest : .work }
}

private struct SavedTimerSession: Codable {
    var phase: NativeTimerPhase
    var workDuration: TimeInterval
    var restDuration: TimeInterval
    var endDate: Date?
    var pausedRemaining: TimeInterval
    var autoAdvance: Bool
}

@MainActor
@Observable
final class NativeTimerSession {
    var phase: NativeTimerPhase = .work
    var workDuration: TimeInterval = 1500
    var restDuration: TimeInterval = 300
    private(set) var endDate: Date?
    private(set) var pausedRemaining: TimeInterval = 1500
    var autoAdvance = true

    @ObservationIgnored private let storageKey = "ajd.studyTimer.native.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let state = try? JSONDecoder().decode(SavedTimerSession.self, from: data) {
            phase = state.phase
            workDuration = max(60, state.workDuration)
            restDuration = max(60, state.restDuration)
            endDate = state.endDate
            pausedRemaining = max(0, state.pausedRemaining)
            autoAdvance = state.autoAdvance
        }
        reconcile()
    }

    var isRunning: Bool { endDate != nil }

    func remaining(at date: Date = .now) -> TimeInterval {
        max(0, endDate.map { $0.timeIntervalSince(date) } ?? pausedRemaining)
    }

    func start(at date: Date = .now) {
        guard endDate == nil else { return }
        endDate = date.addingTimeInterval(max(0, pausedRemaining))
        save()
    }

    func pause(at date: Date = .now) {
        guard endDate != nil else { return }
        pausedRemaining = remaining(at: date)
        endDate = nil
        save()
    }

    func reset() {
        endDate = nil
        pausedRemaining = duration(for: phase)
        save()
    }

    func changePhase(to next: NativeTimerPhase) {
        phase = next
        endDate = nil
        pausedRemaining = duration(for: next)
        save()
    }

    func setDurations(workMinutes: Int, restMinutes: Int) {
        workDuration = TimeInterval(max(1, workMinutes) * 60)
        restDuration = TimeInterval(max(1, restMinutes) * 60)
        reset()
    }

    /// Recomputes after suspension from absolute deadlines (no background JS timer).
    func reconcile(at date: Date = .now) {
        guard var boundary = endDate, boundary <= date else { return }
        if !autoAdvance {
            phase = phase.next
            pausedRemaining = duration(for: phase)
            endDate = nil
            save()
            return
        }

        var transitions = 0
        repeat {
            phase = phase.next
            boundary = boundary.addingTimeInterval(duration(for: phase))
            transitions += 1
        } while boundary <= date && transitions < 10_000

        if boundary <= date {
            boundary = date.addingTimeInterval(duration(for: phase))
        }
        endDate = boundary
        pausedRemaining = duration(for: phase)
        save()
    }

    private func duration(for phase: NativeTimerPhase) -> TimeInterval {
        phase == .work ? workDuration : restDuration
    }

    private func save() {
        let state = SavedTimerSession(
            phase: phase,
            workDuration: workDuration,
            restDuration: restDuration,
            endDate: endDate,
            pausedRemaining: pausedRemaining,
            autoAdvance: autoAdvance
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
