//
//  AudioPlayerProtocol.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AVFoundation
import SwiftUI

protocol AudioPlayerProtocol {
    func play(urlString: String)
    func pause()
}

class AVAudioPlayer: AudioPlayerProtocol {
    private var player = AVPlayer()

    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global(qos: .background).async {
            let playerItem = AVPlayerItem(url: url)
            
            DispatchQueue.main.async {
                self.player.replaceCurrentItem(with: playerItem)
                self.player.play()
            }
        }
    }
    
    func pause() {
        player.pause()
    }
}
