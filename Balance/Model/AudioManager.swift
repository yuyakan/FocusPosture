//
//  AudioManager.swift
//  Balance
//
//  Created by 上別縄祐也 on 2025/08/30.
//

import AVFoundation
import Foundation

class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    enum AudioFile: String, CaseIterable {
        case alert = "alert_music"
        case finish = "finish_music"
        case start = "start_music"
        
        var fileName: String {
            return self.rawValue
        }
    }
    
    func playAudio(_ audioFile: AudioFile) {
        print("AudioManager: Attempting to play \(audioFile.fileName)")
        
        guard let url = Bundle.main.url(forResource: audioFile.fileName, withExtension: "mp3") else {
            print("AudioManager: Could not find audio file: \(audioFile.fileName).mp3 in bundle")
            // バンドル内のリソースをリスト
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("AudioManager: Available files in bundle: \(files.filter { $0.contains("mp3") })")
                } catch {
                    print("AudioManager: Error listing bundle contents: \(error)")
                }
            }
            return
        }
        
        print("AudioManager: Found audio file at: \(url)")
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0
            
            let success = audioPlayer?.play() ?? false
            print("AudioManager: Play command result: \(success)")
            print("AudioManager: Audio player duration: \(audioPlayer?.duration ?? 0)")
            
        } catch {
            print("AudioManager: Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
    }
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
}