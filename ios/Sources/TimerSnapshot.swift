import Foundation

/// The PiP display follows absolute deadlines, including study/break auto-start.
/// Website state remains authoritative; this model never writes cloud records.
struct TimerSnapshot: Codable, Equatable {
    var running: Bool
    var end: Double
    var remaining: Double
    var mode: String
    var title: String
    var focusSeconds: Double
    var breakSeconds: Double
    var autoStart: Bool
    var study: Bool

    static let idle = TimerSnapshot(running: false, end: 0, remaining: 0, mode: "focus", title: "Start a timer", focusSeconds: 1500, breakSeconds: 300, autoStart: false, study: false)

    func hasActiveCountdown(at now: Double) -> Bool {
        running && end > 0 && !display(at: now).finished
    }

    func display(at now: Double) -> (seconds: Int, title: String, finished: Bool) {
        guard running, end > 0 else { return (Int(max(0, remaining).rounded(.up)), title, false) }
        var deadline = end
        var phase = mode
        if study && autoStart && now >= deadline {
            let focus = max(60, focusSeconds), rest = max(60, breakSeconds)
            // Skip full cycles without depending on the WebView executing in background.
            let cycles = floor((now - deadline) / (focus + rest))
            deadline += cycles * (focus + rest)
            for _ in 0..<3 where now >= deadline {
                phase = phase == "focus" ? "break" : "focus"
                deadline += phase == "focus" ? focus : rest
            }
        }
        let seconds = Int(max(0, deadline - now).rounded(.up))
        let label = study ? (phase == "focus" ? "Study time" : "Break time") : title
        return (seconds, label, seconds == 0)
    }
}

