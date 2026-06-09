//
//  TimerView.swift
//  gym-timer Watch App
//
//  Main view: Start / Reset buttons and countdown display.
//  In idle mode the duration can be adjusted with the Digital Crown.
//

import SwiftUI
import WatchKit

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @AppStorage(AppSettingsKey.durationSeconds) private var durationSeconds: Int = AppSettingsDefault.durationSeconds
    @AppStorage(AppSettingsKey.hapticsEnabled)  private var hapticsEnabled: Bool = AppSettingsDefault.hapticsEnabled

    /// Continuous crown value (in seconds). Mirrors `durationSeconds`
    /// but allows smooth scrolling between snapped step values.
    @State private var crownValue: Double = Double(AppSettingsDefault.durationSeconds)

    /// Last snapped value – used to detect step changes for haptics.
    @State private var lastSnappedSeconds: Int = AppSettingsDefault.durationSeconds

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isRunning {
                countdownDisplay
                resetButton
            } else {
                idleDisplay
                startButton
            }
        }
        .padding(.horizontal)
        .navigationTitle(Text("Rest"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            crownValue = Double(durationSeconds)
            lastSnappedSeconds = durationSeconds
        }
    }

    // MARK: - Subviews

    private var idleDisplay: some View {
        VStack(spacing: 6) {
            Text(formatted(seconds: durationSeconds))
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: durationSeconds)
                .focusable(true)
                .digitalCrownRotation(
                    $crownValue,
                    from: Double(DurationLimits.minSeconds),
                    through: Double(DurationLimits.maxSeconds),
                    by: 1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: false // we drive haptics per step ourselves
                )
                .onChange(of: crownValue) { _, newValue in
                    handleCrownChange(newValue)
                }

            Text("Turn crown to adjust")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var countdownDisplay: some View {
        VStack(spacing: 4) {
            Text(formatted(seconds: viewModel.remainingSeconds))
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(viewModel.remainingSeconds <= 3 ? .red : .primary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: viewModel.remainingSeconds)
            Text("running …")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var startButton: some View {
        Button {
            viewModel.start(durationSeconds: durationSeconds)
        } label: {
            Label("Start", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .tint(.green)
        .buttonStyle(.borderedProminent)
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            viewModel.reset()
        } label: {
            Label("Reset", systemImage: "stop.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .tint(.red)
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Crown handling

    private func handleCrownChange(_ newValue: Double) {
        let snapped = DurationLimits.snap(Int(newValue.rounded()))
        guard snapped != lastSnappedSeconds else { return }
        lastSnappedSeconds = snapped
        durationSeconds = snapped
        if hapticsEnabled {
            WKInterfaceDevice.current().play(.click)
        }
    }

    // MARK: - Helpers

    private func formatted(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    NavigationStack {
        TimerView()
    }
}
