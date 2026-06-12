//
//  TimerViewModel.swift
//  gym-timer Watch App
//
//  Drives the countdown for the rest between training sets.
//

import Foundation
import SwiftUI
import WatchKit
import Combine

@MainActor
final class TimerViewModel: NSObject, ObservableObject {

    // MARK: - Published State

    /// Remaining seconds of the current countdown.
    @Published private(set) var remainingSeconds: Int = 0

    /// Whether the timer is currently running.
    @Published private(set) var isRunning: Bool = false

    /// The last few seconds during which we emit tick feedback.
    private let tickThresholdSeconds: Int = 3

    // MARK: - Private State

    private var endDate: Date?

    /// Background dispatch timer – keeps firing even when the watch display
    /// is asleep, as long as an `WKExtendedRuntimeSession` is active.
    /// `Timer` on the main RunLoop would be paused as soon as the user
    /// lowers their wrist, which is exactly the bug we are fixing here.
    private var dispatchTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.gymtimer.countdown", qos: .userInteractive)

    private var lastTickedSecond: Int = -1
    private var didFinish: Bool = false

    /// Extended runtime session that keeps the app in the foreground while
    /// the countdown is running (`.physicalTherapy` is intended for short
    /// fitness/therapy workflows).
    private var runtimeSession: WKExtendedRuntimeSession?

    // MARK: - Public API

    /// Starts the countdown with the given duration in seconds.
    func start(durationSeconds: Int) {
        guard durationSeconds > 0 else { return }

        // Tear down any previous timer/session cleanly.
        invalidateTimer()
        invalidateRuntimeSession()

        remainingSeconds = durationSeconds
        lastTickedSecond = -1
        didFinish = false
        endDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        isRunning = true

        // Make sure audio playback is allowed in the background (display off).
        SoundPlayer.shared.activateSession()

        startRuntimeSession()
        startTimer()

        // Small start cue (respects haptic setting).
        playHaptic(.start)
    }

    /// Resets the running countdown – the UI returns to the Start button.
    func reset() {
        invalidateTimer()
        invalidateRuntimeSession()
        SoundPlayer.shared.deactivateSession()
        remainingSeconds = 0
        endDate = nil
        isRunning = false
        lastTickedSecond = -1
        didFinish = false
    }

    // MARK: - Timer Loop

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        // Tick 4× per second to keep drift low and to deliver accurate
        // tick feedback in the final seconds.
        timer.schedule(deadline: .now() + 0.25, repeating: 0.25, leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            // Hop back to the main actor to mutate @Published state safely.
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        timer.resume()
        dispatchTimer = timer
    }

    private func tick() {
        guard let endDate, !didFinish else { return }

        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))

        if remaining != remainingSeconds {
            remainingSeconds = remaining
        }

        // Tick feedback during the final seconds – once per second.
        if remaining > 0 && remaining <= tickThresholdSeconds && remaining != lastTickedSecond {
            lastTickedSecond = remaining
            playHaptic(.click)
            playSoundTick()
        }

        if remaining <= 0 {
            finish()
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true

        invalidateTimer()

        // Clear end signal: notification haptic + follow-up success.
        playHaptic(.notification)
        playSoundEnd()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.playHaptic(.success)
        }

        isRunning = false
        endDate = nil

        // Keep the audio session active just long enough for the end sound
        // to finish playing, then tear everything down.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.invalidateRuntimeSession()
            SoundPlayer.shared.deactivateSession()
        }
    }

    private func invalidateTimer() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }

    // MARK: - Feedback (Haptics + Sound)

    private var hapticsEnabled: Bool {
        // Default to `true` if the key has never been written yet.
        if UserDefaults.standard.object(forKey: AppSettingsKey.hapticsEnabled) == nil {
            return AppSettingsDefault.hapticsEnabled
        }
        return UserDefaults.standard.bool(forKey: AppSettingsKey.hapticsEnabled)
    }

    private var soundEnabled: Bool {
        if UserDefaults.standard.object(forKey: AppSettingsKey.soundEnabled) == nil {
            return AppSettingsDefault.soundEnabled
        }
        return UserDefaults.standard.bool(forKey: AppSettingsKey.soundEnabled)
    }

    private func playHaptic(_ type: WKHapticType) {
        guard hapticsEnabled else { return }
        WKInterfaceDevice.current().play(type)
    }

    private func playSoundTick() {
        guard soundEnabled else { return }
        SoundPlayer.shared.playTick()
    }

    private func playSoundEnd() {
        guard soundEnabled else { return }
        SoundPlayer.shared.playEnd()
    }

    // MARK: - Extended Runtime Session

    private func startRuntimeSession() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        // `.physicalTherapy` allows long-running foreground sessions for
        // fitness/therapy apps – perfect for gym rest periods.
        session.start()
        runtimeSession = session
    }

    private func invalidateRuntimeSession() {
        runtimeSession?.invalidate()
        runtimeSession = nil
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension TimerViewModel: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // no-op
    }

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // no-op – the timer (max 3 min) will normally have ended well before this.
    }

    nonisolated func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                            didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                            error: Error?) {
        // no-op
    }
}
