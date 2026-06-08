//
//  TimerView.swift
//  gym-timer Watch App
//
//  Main view: Start / Reset buttons and countdown display.
//

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @AppStorage(AppSettingsKey.durationSeconds) private var durationSeconds: Int = AppSettingsDefault.durationSeconds

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
    }

    // MARK: - Subviews

    private var idleDisplay: some View {
        VStack(spacing: 4) {
            Text(formatted(seconds: durationSeconds))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var countdownDisplay: some View {
        VStack(spacing: 4) {
            Text(formatted(seconds: viewModel.remainingSeconds))
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(viewModel.remainingSeconds <= 5 ? .red : .primary)
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
