//
//  SettingsView.swift
//  gym-timer Watch App
//
//  Quick presets for pause duration + sound & haptics toggles.
//  The exact duration is set on the main screen via the Digital Crown.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettingsKey.durationSeconds) private var durationSeconds: Int = AppSettingsDefault.durationSeconds
    @AppStorage(AppSettingsKey.soundEnabled)    private var soundEnabled: Bool   = AppSettingsDefault.soundEnabled
    @AppStorage(AppSettingsKey.hapticsEnabled)  private var hapticsEnabled: Bool = AppSettingsDefault.hapticsEnabled

    private let presets: [(label: LocalizedStringKey, seconds: Int)] = [
        ("0:30", 30),
        ("1:00", 60),
        ("1:30", 90),
        ("2:00", 120),
        ("3:00", 180),
        ("5:00", 300)
    ]

    var body: some View {
        List {
            Section {
                ForEach(presets, id: \.seconds) { preset in
                    Button {
                        durationSeconds = preset.seconds
                    } label: {
                        HStack {
                            Text(preset.label)
                                .monospacedDigit()
                            Spacer()
                            if durationSeconds == preset.seconds {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            } header: {
                Text("Quick presets")
            } footer: {
                Text("Use the Digital Crown on the main screen for fine adjustment.")
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
