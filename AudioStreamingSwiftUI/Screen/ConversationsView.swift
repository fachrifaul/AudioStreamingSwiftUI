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
    private var urlSession: URLSessionProtocol
    private var player: AVPlayer?
    let voiceOption: VoiceOption
    
    init(voiceOption: VoiceOption, urlSession: URLSessionProtocol = URLSession.shared) {
        self.voiceOption = voiceOption
        self.urlSession = urlSession
    }
    
    func fetch() {
        urlSession.dataTask(with: URL(string: voiceOption.transcriptionUrlString)!) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to load text: \(error.localizedDescription)"
                } else if let data = data, let fetchedText = String(data: data, encoding: .utf8) {
                    self.text = fetchedText
                    self.startAudio(url: URL(string: self.voiceOption.soundUrlString)!)
                } else {
                    self.errorMessage = "Failed to decode text."
                }
            }
        }.resume()
    }
    
    func startAudio(url: URL) {
        player = AVPlayer(url: url)
        player?.play()
    }
    
    func stopAudio() {
        player?.pause()
        player = nil
    }
}

struct ConversationsView: View {
    let voiceOption: VoiceOption
    
    init(voiceOption: VoiceOption, urlSession: URLSessionProtocol = URLSession.shared) {
        _viewModel = StateObject(wrappedValue: ConversationsViewModel(voiceOption: voiceOption, urlSession: urlSession))
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
    ConversationsView(
        voiceOption: VoiceOption(
            voiceId: 1, 
            sampleId: 1,
            name: "Stone"
        )
    )
}
