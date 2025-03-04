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
         audioPlayer: AudioPlayerProtocol = AudioPlayerQueue()) {
        self.voiceOption = voiceOption
        self.api = api
        self.audioPlayer = audioPlayer
    }
    
    @MainActor
    func fetch(stepId: Int = 1) async {
        do {
            let token = try await api.getValidJWTToken()
            
            audioPlayer.playStream(voiceId: voiceOption.voiceId, stepId: 1, token: token, onTranscription: { headers in
                if let text = headers["x-dailyfriend-onboarding-current-step-transcription"] as? String {
                    DispatchQueue.main.async { [weak self] in
                        self?.text = text
                    }
                }
            }, onComplete: {
                if (stepId <= 3) {
                    Task {
                        await self.fetch(stepId: stepId + 1)
                    }
                }
            })
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "error"
            }
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
