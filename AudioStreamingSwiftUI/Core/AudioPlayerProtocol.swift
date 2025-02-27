//
//  AudioPlayerProtocol.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AVFoundation
import AudioStreaming
import SwiftUI

protocol AudioPlayerProtocol {
    func play(urlString: String)
    func pause()
    func stop()
}

class AVAudioPlayer: AudioPlayerProtocol {
    private var player: AVPlayer?
    
    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global(qos: .background).async {
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            DispatchQueue.main.async {
                self.player = AVPlayer(playerItem: playerItem)
                self.player?.play()
            }
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }
}

class AudioPlayerStreaming: AudioPlayerProtocol {
    private var player: AudioPlayer?
    
    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        player = AudioPlayer()
        player?.play(url: url)
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
    }
}
