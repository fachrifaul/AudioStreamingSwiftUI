//
//  ConversationsView.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AVFoundation
import Lottie
import SwiftUI

@MainActor
class ConversationsState: ObservableObject {
    @Published var text: String? = nil
    @Published var errorMessage: String? = nil
    @Published var voiceOption: VoiceOption?
}

@MainActor
class ConversationsViewModel: @preconcurrency AudioPlayerDelegate {
    private var state: ConversationsState
    private var api: API
    private var audioPlayer: AudioPlayerProtocol
    let voiceOption: VoiceOption
    
    init(state: ConversationsState,
         voiceOption: VoiceOption,
         api: API = API(),
         audioPlayer: AudioPlayerProtocol? = nil) {
        self.state = state
        self.voiceOption = voiceOption
        self.api = api
        self.audioPlayer = audioPlayer ?? AudioPlayerQueue(api: api)
    }
    
    func fetch(stepId: Int = 1) {
        audioPlayer.delegate = self
        audioPlayer.playStream(
            body: [
                "voice_id": voiceOption.voiceId,
                "step_id": stepId,
                "audio_format": "pcm"
            ]
        )
    }
    
    func fetchAsync(stepId: Int = 1) async {
        audioPlayer.delegate = self
        audioPlayer.playStream2(
            body: [
                "voice_id": voiceOption.voiceId,
                "step_id": stepId,
                "audio_format": "pcm"
            ]
        )
    }
    
    func onTranscription(text: String) {
        state.text = text
    }
    
    func onComplete(nextStepId: Int) {
        fetch(stepId: nextStepId)
    }
    
    func startAudio(urlString: String) {
        audioPlayer.play(urlString: urlString)
    }
    
    func stopAudio() {
        audioPlayer.stop()
    }
}

struct ConversationsPage: View {
    @StateObject private var state: ConversationsState
    private var viewModel: ConversationsViewModel
    let voiceOption: VoiceOption
    
    init(
        state: ConversationsState = ConversationsState(),
        voiceOption: VoiceOption,
        urlSession: URLSessionProtocol = URLSession.shared
    ) {
        self._state = StateObject(wrappedValue: state)
        self.viewModel = ConversationsViewModel(
            state: state,
            voiceOption: voiceOption
        )
        self.voiceOption = voiceOption
    }
    
    var body: some View {
        VStack(spacing: 20) {
            LottieView {
                await LottieAnimation.loadedFrom(
                    url: URL(string: "https://static.dailyfriend.ai/images/mascot-animation.json")!
                )?.animationSource
            } placeholder: {
                ProgressView()
                    .frame(width: 50, height: 50)
            }
            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
            .intrinsicSize()
            .frame(maxWidth:.infinity, maxHeight: .infinity)
            .aspectRatio(contentMode: .fit)
            
            if let errorMessage = state.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                Button("Retry") {
                    state.errorMessage = nil
                    fetch()
                }
                .padding()
            } else if let text = state.text {
                Text(text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }  else {
                ProgressView("Loading...")
                    .padding()
            }
        }
        .onAppear {
            fetch()
        }
//        .task {
//            await viewModel.fetchAsync()
//        }
        .onDisappear {
            viewModel.stopAudio()
        }
    }
    
    private func fetch() {
        viewModel.fetch()
    }
}

#Preview {
    ConversationsPage(
        voiceOption: VoiceOption(
            voiceId: 1,
            sampleId: 1,
            name: "Stone"
        )
    )
}
