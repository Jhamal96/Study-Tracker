import AVFoundation
import AVKit
import CoreMedia
import CoreVideo
import UIKit

@MainActor
final class SampleBufferView: UIView {
    override class var layerClass: AnyClass { AVSampleBufferDisplayLayer.self }
    var displayLayer: AVSampleBufferDisplayLayer { layer as! AVSampleBufferDisplayLayer }
}

/// Experimental real media PiP: renders countdown frames without camera or microphone.
@MainActor
final class NativeTimerPiP: NSObject, AVPictureInPictureControllerDelegate, AVPictureInPictureSampleBufferPlaybackDelegate {
    var onStatus: ((String) -> Void)?
    private var layer: AVSampleBufferDisplayLayer?
    private var controller: AVPictureInPictureController?
    private var possibility: NSKeyValueObservation?
    private var renderTimer: Timer?
    private var state = TimerSnapshot.idle
    private var startRequested = false
    private var timeout: DispatchWorkItem?
    private var format: CMVideoFormatDescription?
    private var pool: CVPixelBufferPool?
    private let width = 640
    private let height = 360

    func attach(to layer: AVSampleBufferDisplayLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            onStatus?("System Picture-in-Picture is unavailable on this device.")
            return
        }
        self.layer = layer
        layer.videoGravity = .resizeAspect
        let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: layer, playbackDelegate: self)
        let pip = AVPictureInPictureController(contentSource: source)
        controller = pip
        pip.delegate = self
        pip.requiresLinearPlayback = true
        // PiP opens only after the user taps Float Timer.
        pip.canStartPictureInPictureAutomaticallyFromInline = false
        possibility = pip.observe(\.isPictureInPicturePossible, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in self?.startIfPossible() }
        }
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        CVPixelBufferPoolCreate(nil, nil, attrs as CFDictionary, &pool)
        render()
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if UIApplication.shared.applicationState == .active || self.controller?.isPictureInPictureActive == true {
                    self.render()
                }
            }
        }
    }

    func update(_ snapshot: TimerSnapshot) {
        let changed = state.running != snapshot.running
        state = snapshot
        render()
        if changed { controller?.invalidatePlaybackState() }
    }

    func start() {
        guard let controller else {
            onStatus?("System Picture-in-Picture is unavailable on this device.")
            return
        }
        if controller.isPictureInPictureActive { controller.stopPictureInPicture(); return }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try audio.setActive(true)
        } catch {
            onStatus?("Could not activate the PiP media session: \(error.localizedDescription)")
            return
        }
        startRequested = true
        render()
        onStatus?("Preparing system Picture-in-Picture…")
        timeout?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.startRequested else { return }
            self.startRequested = false
            self.onStatus?("iOS did not allow PiP to start. Keep the app visible and check Settings → General → Picture in Picture.")
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
        startIfPossible()
    }

    private func startIfPossible() {
        guard startRequested, controller?.isPictureInPicturePossible == true else { return }
        controller?.startPictureInPicture()
    }

    private func render() {
        guard let layer, let pool else { return }
        var buffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess, let buffer else { return }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { return }
        ctx.setFillColor(UIColor(red: 0.10, green: 0.08, blue: 0.15, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        // UIKit text drawing uses a top-left origin.
        ctx.translateBy(x: 0, y: CGFloat(height)); ctx.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(ctx)
        let display = state.display(at: Date().timeIntervalSince1970)
        let accent = UIColor(red: 0.98, green: 0.77, blue: 0.88, alpha: 1)
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        func text(_ text: String, y: CGFloat, size: CGFloat, color: UIColor, weight: UIFont.Weight = .semibold) {
            (text as NSString).draw(in: CGRect(x: 16, y: y, width: CGFloat(width) - 32, height: size * 1.7), withAttributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
                .foregroundColor: color, .paragraphStyle: paragraph
            ])
        }
        text(state.study ? "STUDY TIMER" : "BREAK TRACKER", y: 24, size: 19, color: accent)
        text(String(format: "%02d:%02d", display.seconds / 60, display.seconds % 60), y: 102, size: 92, color: .white, weight: .bold)
        text(display.title, y: 236, size: 25, color: accent)
        text(display.finished ? "Timer finished" : state.running ? "Time remaining" : "Ready when you are", y: 289, size: 17, color: .lightGray)
        UIGraphicsPopContext()
        if format == nil { CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescriptionOut: &format) }
        guard let format else { return }
        var timing = CMSampleTimingInfo(duration: CMTime(seconds: 0.5, preferredTimescale: 600),
                                        presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600), decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescription: format, sampleTiming: &timing, sampleBufferOut: &sample) == noErr, let sample else { return }
        let renderer = layer.sampleBufferRenderer
        if renderer.isReadyForMoreMediaData { renderer.enqueue(sample) }
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        startRequested = false; timeout?.cancel()
        onStatus?("System PiP is active. You can return to the Home Screen.")
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        onStatus?("PiP closed. The timer continues in the tracker.")
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        startRequested = false; timeout?.cancel()
        onStatus?("PiP could not start: \(error.localizedDescription)")
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        // This countdown is tied to a wall-clock deadline, not video playback rate.
        // Pause/resume is controlled on the tracker so both views stay in sync.
        pictureInPictureController.invalidatePlaybackState()
    }
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool { false }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) { completionHandler() }

    deinit { renderTimer?.invalidate(); timeout?.cancel() }
}
