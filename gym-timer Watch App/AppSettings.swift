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
