//
//  GreetingsView.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AVFoundation
import Lottie
import SwiftUI

@MainActor
class GreetingsState: ObservableObject {
    @Published var voices: [VoiceOption] = []
    @Published var selectedVoice: VoiceOption?
    @Published var errorMessage: String? = nil
    @Published var isLoaded: Bool = false
}

@MainActor
class GreetingsViewModel {
    private var state: GreetingsState
    private var audioPlayer: AudioPlayerProtocol
    private var voicesUseCase: VoicesUseCase
    
    init(
        state: GreetingsState,
        audioPlayer: AudioPlayerProtocol = AVAudioPlayer(),
        voicesUseCase: VoicesUseCase = VoicesUseCase()
    ) {
        self.state = state
        self.audioPlayer = audioPlayer
        self.voicesUseCase = voicesUseCase
    }
    
    func fetchVoices() {
        Task {
            let result = await voicesUseCase.call()
            switch result {
            case .success(let voices):
                self.state.voices = voices
            case .failure(let error):
                self.state.errorMessage = error.localizedDescription
            }
        }
    }
    
    func selectVoice(_ voice: VoiceOption) {
        if let _ = state.selectedVoice {
            audioPlayer.pause()
        }
        state.selectedVoice = voice
        playSound(urlString: voice.soundUrlString)
    }
    
    func playSound(urlString: String) {
        audioPlayer.play(urlString: urlString)
    }
    
    func stopAudio() {
        audioPlayer.stop()
    }
}

struct GreetingsPage: View {
    @StateObject private var state: GreetingsState
    private var viewModel: GreetingsViewModel
    
    init(state: GreetingsState = GreetingsState()) {
        self._state = StateObject(wrappedValue: state)
        self.viewModel = GreetingsViewModel(state: state)
    }
    
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
                
                if let errorMessage = state.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        state.errorMessage = nil
                        viewModel.fetchVoices()
                    }
                    .padding()
                } else if !state.voices.isEmpty {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        ForEach(Array(state.voices.enumerated()), id: \.element.id) { index, voice in
                            VoiceButtonView(
                                index: index,
                                voice: voice,
                                selectedVoice: $state.selectedVoice
                            ) {
                                viewModel.selectVoice(voice)
                                playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    NavigationLink(
                        destination: {
                            if let selectedVoice = state.selectedVoice {
                                ConversationsPage(voiceOption: selectedVoice)
                            } else {
                                EmptyView()
                            }
                        }
                    ) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(state.selectedVoice == nil ? Color.gray.opacity(0.5) : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }.disabled(state.selectedVoice == nil)
                }  else {
                    ProgressView("Loading...")
                        .padding()
                }
            }
            .padding()
            .task {
                if (!state.isLoaded) {
                    state.isLoaded = true
                    viewModel.fetchVoices()
                }
            }
            .onDisappear {
                viewModel.stopAudio()
            }
        }
    }
}

#Preview {
    GreetingsPage()
}
