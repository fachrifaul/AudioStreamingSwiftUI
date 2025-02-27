//
//  GreetingsView.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AVFoundation
import Lottie
import SDWebImageSwiftUI
import SwiftUI

class GreetingsViewModel: ObservableObject {
    @Published var voices: [VoiceOption] = []
    @Published var selectedVoice: VoiceOption?
    @Published var errorMessage: String? = nil
    
    private var audioPlayer: AudioPlayerProtocol
    private var api: API
    
    init(
        audioPlayer: AudioPlayerProtocol = AVAudioPlayer(),
        api: API = API()
    ) {
        self.audioPlayer = audioPlayer
        self.api = api
    }
    
    func fetchVoices() {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            let voices = [
                VoiceOption(voiceId: 1, sampleId: 1, name: "Meadow"),
                VoiceOption(voiceId: 2, sampleId: 1, name: "Cypress"),
                VoiceOption(voiceId: 3, sampleId: 1, name: "Iris"),
                VoiceOption(voiceId: 4, sampleId: 1, name: "Hawke"),
                VoiceOption(voiceId: 5, sampleId: 1, name: "Seren"),
                VoiceOption(voiceId: 6, sampleId: 1, name: "Stone")
            ]
            DispatchQueue.main.async {
                self.voices = voices
            }
        }
    }
    
    @MainActor
    func fetchGreetings() async {
        let result = await api.fetchGreetings()
        switch result {
        case .success(let voices):
            self.voices = voices
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func selectVoice(_ voice: VoiceOption) {
        selectedVoice = voice
        playSound(urlString: voice.soundUrlString)
    }
    
    func playSound(urlString: String) {
        audioPlayer.play(urlString: urlString)
    }
    
    func pauseAudio() {
        audioPlayer.pause()
    }
}

struct GreetingsPage: View {
    @StateObject private var viewModel = GreetingsViewModel()
    @State private var playbackMode: LottiePlaybackMode =
        .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Pick my voice")
                    .font(.title)
                
                LottieView {
                    await LottieAnimation.loadedFrom(
                        url: URL(string: "https://static.dailyfriend.ai/images/mascot-animation.json")!
                    )?.animationSource
                } placeholder: {
                    ProgressView()
                        .frame(width: 50, height: 50)
                }
                .playbackMode(playbackMode)
                .intrinsicSize()
                .animationDidFinish { completed in
                    playbackMode = LottiePlaybackMode.paused
                }
                .frame(maxWidth: 70, maxHeight: 70)
                .aspectRatio(contentMode: .fit)
                
                Text("Find the voice that resonates with you")
                    .font(.subheadline)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        viewModel.errorMessage = nil
                        viewModel.fetchVoices()
                    }
                    .padding()
                } else if !viewModel.voices.isEmpty {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        ForEach(Array(viewModel.voices.enumerated()), id: \.element.id) { index, voice in
                            VoiceButtonView(index: index, voice: voice, selectedVoice: $viewModel.selectedVoice) {
                                viewModel.selectVoice(voice)
                                playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    NavigationLink(
                        destination: {
                            if let selectedVoice = viewModel.selectedVoice {
                                ConversationsPage(voiceOption: selectedVoice)
                            } else {
                                EmptyView()
                            }
                        }
                    ) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedVoice == nil ? Color.gray.opacity(0.5) : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }.disabled(viewModel.selectedVoice == nil)
                }  else {
                    ProgressView("Loading...")
                        .padding()
                }
            }
            .padding()
            .onAppear {
                viewModel.fetchVoices()
            }
            .onDisappear {
                viewModel.pauseAudio()
            }
        }
    }
}

struct VoiceButtonView: View {
    let index: Int
    let voice: VoiceOption
    @Binding var selectedVoice: VoiceOption?
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack {
                HStack {
                    Text(voice.name)
                        .font(.headline)
                    Spacer()
                    Image(systemName: circleImage(selectedVoice?.id == voice.id))
                        .foregroundColor(.orange)
                }
                
                WebImage(url: URL(string: voice.imageUrlString))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
            }
            .padding()
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedVoice?.id == voice.id ? borderColor() : Color.clear, lineWidth: 2)
                    .background(bgColor())
                
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func borderColor() -> Color {
        return index % 2 == 0 ? Color.borderPink : Color.borderOrange
    }
    
    private func bgColor() -> Color {
        return index % 2 == 0 ? Color.bgPink : Color.bgOrange
    }
    
    private func circleImage(_ isFillCircle: Bool) -> String {
        return isFillCircle ? "largecircle.fill.circle" : "circle"
    }
}

#Preview {
    GreetingsPage()
}
