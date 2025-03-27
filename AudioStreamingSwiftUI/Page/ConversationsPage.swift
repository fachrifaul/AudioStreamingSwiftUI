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
class ConversationsViewModel: ObservableObject, @preconcurrency AudioPlayerDelegate {
    @Published var text: String? = nil
    @Published var errorMessage: String? = nil
    private var api: API
    private var audioPlayer: AudioPlayerProtocol
    let voiceOption: VoiceOption
    
    init(voiceOption: VoiceOption, 
         api: API = API(),
         audioPlayer: AudioPlayerProtocol? = nil) {
        self.voiceOption = voiceOption
        self.api = api
        self.audioPlayer = audioPlayer ?? AudioPlayerQueue(api: api)
    }
    
    func fetch(stepId: Int = 1) {
        audioPlayer.delegate = self
        //        startAudio(urlString: "https://file-examples.com/storage/fe7502810367c61059aaa19/2017/11/file_example_WAV_1MG.wav")
        //        return
        do {
            let body: [String: Any] = [
                "voice_id": voiceOption.voiceId,
                "step_id": stepId,
                "audio_format": "pcm"
            ]
            audioPlayer.playStream(body: body, stepId: stepId)
        } catch {
            self.errorMessage = "error"
        }
    }
    
    func onTranscription(headers: ([AnyHashable : Any])) {
        if let text = headers["x-dailyfriend-onboarding-current-step-transcription"] as? String {
            self.text = text
        }
    }
    
    func complete(stepId: Int) {
        if (stepId <= 3) {
            fetch(stepId: stepId + 1)
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
