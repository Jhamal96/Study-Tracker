import XCTest
@testable import StudyTimerApple

final class TimerClockTests: XCTestCase {
    func testCountdownUsesDeadlineEvenWhenTicksWereMissed() {
        let s = TimerSnapshot(running: true, end: 1100, remaining: 999, mode: "focus", title: "Study time", focusSeconds: 1500, breakSeconds: 300, autoStart: false, study: true)
        XCTAssertEqual(s.display(at: 1042).seconds, 58)
        XCTAssertTrue(s.display(at: 1100).finished)
        XCTAssertEqual(s.display(at: 1200).seconds, 0)
    }
    func testAutoStartCrossesStudyAndBreakWithNoWebViewUpdates() {
        let s = TimerSnapshot(running: true, end: 1000, remaining: 0, mode: "focus", title: "Study time", focusSeconds: 1500, breakSeconds: 300, autoStart: true, study: true)
        XCTAssertEqual(s.display(at: 1000).title, "Break time")
        XCTAssertEqual(s.display(at: 1000).seconds, 300)
        XCTAssertEqual(s.display(at: 1350).title, "Study time")
        XCTAssertEqual(s.display(at: 1350).seconds, 1450)
        XCTAssertEqual(s.display(at: 11800).title, "Break time")
        XCTAssertEqual(s.display(at: 11800).seconds, 300)
    }
    func testPausedTimerDoesNotAdvanceOrAutoStart() {
        let s = TimerSnapshot(running: false, end: 0, remaining: 98.2, mode: "break", title: "Break time", focusSeconds: 1500, breakSeconds: 300, autoStart: true, study: true)
        XCTAssertEqual(s.display(at: 999999).seconds, 99)
    }
    func testBreakUsesItsOwnReturnTimeWithoutInventingNextBreak() {
        let s = TimerSnapshot(running: true, end: 1000, remaining: 0, mode: "focus", title: "Kitt_305 · Lunch", focusSeconds: 1500, breakSeconds: 300, autoStart: true, study: false)
        XCTAssertEqual(s.display(at: 1030).seconds, 0)
        XCTAssertEqual(s.display(at: 1030).title, "Kitt_305 · Lunch")
    }

    func testOnlyLiveCountdownsCanArmAutomaticPiP() {
        XCTAssertFalse(TimerSnapshot.idle.hasActiveCountdown(at: 900))
        var s = TimerSnapshot(running: true, end: 1000, remaining: 999, mode: "focus", title: "Lunch", focusSeconds: 1500, breakSeconds: 300, autoStart: false, study: false)
        XCTAssertTrue(s.hasActiveCountdown(at: 999))
        XCTAssertFalse(s.hasActiveCountdown(at: 1000))
        s.running = false
        XCTAssertFalse(s.hasActiveCountdown(at: 900))
    }

    func testAutomaticPiPStaysEligibleAcrossStudyAutoStartPhases() {
        var s = TimerSnapshot(running: true, end: 1000, remaining: 0, mode: "focus", title: "Study time", focusSeconds: 1500, breakSeconds: 300, autoStart: true, study: true)
        XCTAssertTrue(s.hasActiveCountdown(at: 1000))
        XCTAssertTrue(s.hasActiveCountdown(at: 1300))
        XCTAssertTrue(s.hasActiveCountdown(at: 11800))
        s.autoStart = false
        XCTAssertFalse(s.hasActiveCountdown(at: 1000))
    }
}

