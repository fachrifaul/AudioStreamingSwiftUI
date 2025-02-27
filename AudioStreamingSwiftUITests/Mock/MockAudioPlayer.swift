//
//  MockAudioPlayer.swift
//  AudioStreamingSwiftUITests
//
//  Created by Fachri Febrian on 26/02/2025.
//

import Foundation
@testable import AudioStreamingSwiftUI

class MockAudioPlayer: AudioPlayerProtocol {
    var playedURL: String?
    var pauseCalled = false
    var stopCalled = false

    func play(urlString: String) {
        playedURL = urlString
    }
    
    func pause() {
        pauseCalled = true
    }
    func stop() {
        stopCalled = true
    }
}
