//
//  ConversationsView.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AVFoundation
import Lottie
import SwiftUI

class ConversationsViewModel: ObservableObject {
    @Published var text: String? = nil
    @Published var errorMessage: String? = nil
    private var api: API
    private var audioPlayer: AudioPlayerProtocol
    let voiceOption: VoiceOption
    
    init(voiceOption: VoiceOption, 
         api: API = API(),
         audioPlayer: AudioPlayerProtocol = AVAudioPlayer()) {
        self.voiceOption = voiceOption
        self.api = api
        self.audioPlayer = audioPlayer
    }
    
    @MainActor
    func fetch(randomSampleId: Int = Int.random(in: 2...20)) async {
        let result = await api.fetchTransciption(voiceId: voiceOption.voiceId, sampleId: randomSampleId)
        switch result {
        case .success(let text):
            self.text = text
            self.startAudio(urlString: API.soundUrlString(voiceId: voiceOption.voiceId, sampleId: randomSampleId))
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func startAudio(urlString: String) {
        audioPlayer.play(urlString: urlString)
    }
    
    func stopAudio() {
        audioPlayer.stop()
    }
}

struct ConversationsPage: View {
    let voiceOption: VoiceOption
    
    init(voiceOption: VoiceOption, urlSession: URLSessionProtocol = URLSession.shared) {
        _viewModel = StateObject(wrappedValue: ConversationsViewModel(voiceOption: voiceOption))
        self.voiceOption = voiceOption
    }
    
    @StateObject private var viewModel: ConversationsViewModel
    
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
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                Button("Retry") {
                    viewModel.errorMessage = nil
                    fetch()
                }
                .padding()
            } else if let text = viewModel.text {
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
        .onDisappear {
            viewModel.stopAudio()
        }
    }
    
    private func fetch() {
        Task {
            await viewModel.fetch()
        }
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
