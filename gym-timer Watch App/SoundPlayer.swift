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
        configureAudioSessionCategory()
        tickPlayer = loadPlayer(named: "tick", ext: "wav")
        endPlayer = loadPlayer(named: "end", ext: "wav")
    }

    // MARK: - Public API

    /// Activates the shared `AVAudioSession`. Call this right before the
    /// countdown starts so audio keeps playing when the watch display turns
    /// off (wrist lowered).
    func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: [])
        } catch {
            // Silently fail – audio is a nice-to-have.
        }
    }

    /// Deactivates the audio session, e.g. when the countdown finishes or
    /// is reset, so other audio sources can resume normally.
    func deactivateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // ignore
        }
    }

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

    private func configureAudioSessionCategory() {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.playback` ensures audio is audible even when the watch is in
            // silent / muted state for notifications. `.duckOthers` lowers
            // any concurrent media (e.g. music) for the short tick/end cue.
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        } catch {
            // Silently fail – audio is a nice-to-have, the timer still works.
        }
    }
}
