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
    private var timer: Timer?
    private var lastTickedSecond: Int = -1

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
        endDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        isRunning = true

        startRuntimeSession()
        startTimer()

        // Small start cue (respects haptic setting).
        playHaptic(.start)
    }

    /// Resets the running countdown – the UI returns to the Start button.
    func reset() {
        invalidateTimer()
        invalidateRuntimeSession()
        remainingSeconds = 0
        endDate = nil
        isRunning = false
        lastTickedSecond = -1
    }

    // MARK: - Timer Loop

    private func startTimer() {
        // Tick 4× per second to keep drift low and to deliver accurate
        // tick feedback in the final seconds.
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard let endDate else { return }

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
        invalidateTimer()

        // Clear end signal: notification haptic + follow-up success.
        playHaptic(.notification)
        playSoundEnd()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.playHaptic(.success)
        }

        isRunning = false
        endDate = nil
        invalidateRuntimeSession()
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
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
