//
//  SoundPlayer.swift
//  gym-timer Watch App
//
//  Plays short tick/end sounds from the app bundle using AVAudioPlayer.
//

import Foundation
import AVFoundation

final class SoundPlayer {

    static let shared = SoundPlayer()

    private var tickPlayer: AVAudioPlayer?
    private var endPlayer: AVAudioPlayer?

    private init() {
        configureAudioSession()
        tickPlayer = loadPlayer(named: "tick", ext: "wav")
        endPlayer = loadPlayer(named: "end", ext: "wav")
    }

    // MARK: - Public API

    func playTick() {
        play(tickPlayer)
    }

    func playEnd() {
        play(endPlayer)
    }

    // MARK: - Helpers

    private func play(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    private func loadPlayer(named name: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.playback` ensures audio is audible even when the watch is in
            // silent / muted state for notifications.
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            // Silently fail – audio is a nice-to-have, the timer still works.
        }
    }
}
