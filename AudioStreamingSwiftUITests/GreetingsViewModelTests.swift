//
//  GreetingsViewModelTests.swift
//  AudioStreamingSwiftUITests
//
//  Created by Fachri Febrian on 26/02/2025.
//

import XCTest
@testable import AudioStreamingSwiftUI

final class GreetingsViewModelTests: XCTestCase {
    var viewModel: GreetingsViewModel!
    var mockAudioPlayer: MockAudioPlayer!

    override func setUp() {
        super.setUp()
        mockAudioPlayer = MockAudioPlayer()
        viewModel = GreetingsViewModel(audioPlayer: mockAudioPlayer)
    }

    func testSelectVoice_updatesSelectedVoice() {
        let voice = VoiceOption(voiceId: 1, name: "Meadow")
        
        viewModel.selectVoice(voice)
        
        XCTAssertEqual(viewModel.selectedVoice?.id, voice.id)
        XCTAssertEqual(mockAudioPlayer.playedURL, "https://static.dailyfriend.ai/conversations/samples/1/1/audio.mp3")
    }

    func testPauseAudio_callsPauseOnAudioPlayer() {
        viewModel.pauseAudio()
        
        XCTAssertTrue(mockAudioPlayer.pauseCalled)
    }
}
