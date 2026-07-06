//
//  AudioService.swift
//  alif-baa-ios
//
//  Offline audio over AVFoundation (§4.6, §5.1). Bundled recordings play when
//  present; until a native speaker records them (§7.1), synthesized placeholder
//  tones stand in — mirroring the prototype's placeholderAudio flag.
//

import Foundation
import AVFoundation

final class AudioService {

    static let shared = AudioService()

    /// True while letter audio is synthesized rather than recorded (§4.6).
    private(set) var placeholderAudio = true

    /// Gated by the Settings "Sound effects" toggle (§4.5); letter pronunciation always plays.
    var soundEffectsEnabled = true

    private var player: AVAudioPlayer?
    private var toneCache: [String: Data] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Pronunciation

    func playLetter(id: Int, audioFile: String) {
        if playBundled(audioFile) {
            placeholderAudio = false
            return
        }
        playTone(frequency: Self.frequency(forLetter: id))
    }

    func playLetter(id: Int, audioFile: String, harakat: Harakat) {
        let vowelled = audioFile.replacingOccurrences(of: ".m4a", with: "-\(harakat.rawValue).m4a")
        if playBundled(vowelled) {
            placeholderAudio = false
            return
        }
        playTone(frequency: Self.frequency(forLetter: id) * harakat.toneMultiplier, duration: 0.7)
    }

    func playWord(_ word: Word) {
        if playBundled(word.audioFile) { return }
        playTone(frequency: 330, duration: 0.9)
    }

    // MARK: - Feedback effects

    func playCorrect() {
        guard soundEffectsEnabled else { return }
        playTone(frequency: 1047, duration: 0.18)
    }

    func playWrong() {
        guard soundEffectsEnabled else { return }
        playTone(frequency: 196, duration: 0.3)
    }

    // MARK: - Placeholder synthesis

    /// A distinct semitone per letter so the sound exercises are playable
    /// before real recordings exist.
    static func frequency(forLetter id: Int) -> Double {
        220 * pow(2, Double(id) / 12.0)
    }

    private func playBundled(_ file: String) -> Bool {
        guard !file.isEmpty else { return false }
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? "m4a" : ext),
              let audioPlayer = try? AVAudioPlayer(contentsOf: url) else { return false }
        player = audioPlayer
        audioPlayer.play()
        return true
    }

    private func playTone(frequency: Double, duration: Double = 0.55) {
        let key = "\(Int(frequency.rounded()))-\(Int(duration * 1000))"
        let data: Data
        if let cached = toneCache[key] {
            data = cached
        } else {
            data = Self.sineWAV(frequency: frequency, duration: duration)
            toneCache[key] = data
        }
        guard let audioPlayer = try? AVAudioPlayer(data: data) else { return }
        player = audioPlayer
        audioPlayer.play()
    }

    /// 16-bit mono PCM WAV at 22,050 Hz (§4.6's target format), generated in memory:
    /// a sine with a soft second harmonic and 15 ms fades to avoid clicks.
    static func sineWAV(frequency: Double, duration: Double, sampleRate: Double = 22050) -> Data {
        let frameCount = Int(sampleRate * duration)
        let fadeFrames = Int(sampleRate * 0.015)

        var samples = Data(capacity: frameCount * 2)
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var value = sin(2 * .pi * frequency * t) * 0.8
                + sin(4 * .pi * frequency * t) * 0.15
            if i < fadeFrames {
                value *= Double(i) / Double(fadeFrames)
            } else if i > frameCount - fadeFrames {
                value *= Double(frameCount - i) / Double(fadeFrames)
            }
            let sample = Int16(max(-1, min(1, value * 0.9)) * Double(Int16.max))
            withUnsafeBytes(of: sample.littleEndian) { samples.append(contentsOf: $0) }
        }

        var wav = Data()
        func append(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) } }
        func append(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) } }

        wav.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36 + samples.count))
        wav.append(contentsOf: Array("WAVE".utf8))
        wav.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16))                        // fmt chunk size
        append(UInt16(1))                         // PCM
        append(UInt16(1))                         // mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2))            // byte rate
        append(UInt16(2))                         // block align
        append(UInt16(16))                        // bits per sample
        wav.append(contentsOf: Array("data".utf8))
        append(UInt32(samples.count))
        wav.append(samples)
        return wav
    }
}
