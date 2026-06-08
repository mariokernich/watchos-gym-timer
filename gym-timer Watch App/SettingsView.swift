//
//  SettingsView.swift
//  gym-timer Watch App
//
//  Pause duration (1/2/3 minutes) + sound & haptics toggles.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettingsKey.durationSeconds) private var durationSeconds: Int = AppSettingsDefault.durationSeconds
    @AppStorage(AppSettingsKey.soundEnabled)    private var soundEnabled: Bool   = AppSettingsDefault.soundEnabled
    @AppStorage(AppSettingsKey.hapticsEnabled)  private var hapticsEnabled: Bool = AppSettingsDefault.hapticsEnabled

    private let options: [(label: LocalizedStringKey, seconds: Int)] = [
        ("1 Minute",  60),
        ("2 Minutes", 120),
        ("3 Minutes", 180)
    ]

    var body: some View {
        List {
            Section("Timer length") {
                ForEach(options, id: \.seconds) { option in
                    Button {
                        durationSeconds = option.seconds
                    } label: {
                        HStack {
                            Text(option.label)
                            Spacer()
                            if durationSeconds == option.seconds {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }

            Section("Feedback") {
                Toggle(isOn: $soundEnabled) {
                    Label("Sound", systemImage: "speaker.wave.2.fill")
                }
                Toggle(isOn: $hapticsEnabled) {
                    Label("Haptics", systemImage: "waveform.path")
                }
            }
        }
        .navigationTitle(Text("Settings"))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
