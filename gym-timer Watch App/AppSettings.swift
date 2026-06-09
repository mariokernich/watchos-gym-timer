//
//  AppSettings.swift
//  gym-timer Watch App
//
//  Central place for user-defaults keys & default values.
//

import Foundation

enum AppSettingsKey {
    static let durationSeconds = "timerDurationSeconds"
    static let soundEnabled    = "soundEnabled"
    static let hapticsEnabled  = "hapticsEnabled"
}

enum AppSettingsDefault {
    static let durationSeconds = 60
    static let soundEnabled    = true
    static let hapticsEnabled  = true
}

/// Limits and step sizes for the user-adjustable timer duration.
enum DurationLimits {
    /// Minimum selectable duration (5 seconds).
    static let minSeconds: Int = 5
    /// Maximum selectable duration (10 minutes).
    static let maxSeconds: Int = 10 * 60

    /// Returns a context-sensitive step size, so the Digital Crown
    /// feels precise for short durations and quick for long ones.
    static func step(forSeconds seconds: Int) -> Int {
        switch seconds {
        case ..<60:   return 5    // < 1 min  →  5 s
        case ..<300:  return 15   // < 5 min  → 15 s
        default:      return 30   // ≥ 5 min  → 30 s
        }
    }

    /// Snaps an arbitrary value to the nearest valid step.
    static func snap(_ value: Int) -> Int {
        let clamped = min(max(value, minSeconds), maxSeconds)
        let step = step(forSeconds: clamped)
        let snapped = Int((Double(clamped) / Double(step)).rounded()) * step
        return min(max(snapped, minSeconds), maxSeconds)
    }
}
