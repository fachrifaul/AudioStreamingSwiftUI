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
    let voices = [
        VoiceOption(voiceId: 1, sampleId: 1, name: "Meadow"),
        VoiceOption(voiceId: 2, sampleId: 1, name: "Cypress"),
        VoiceOption(voiceId: 3, sampleId: 1, name: "Iris"),
        VoiceOption(voiceId: 4, sampleId: 1, name: "Hawke"),
        VoiceOption(voiceId: 5, sampleId: 1, name: "Seren"),
        VoiceOption(voiceId: 6, sampleId: 1, name: "Stone")
    ]
    
    @Published var selectedVoice: VoiceOption?
    private var audioPlayer: AudioPlayerProtocol

    init(audioPlayer: AudioPlayerProtocol = AVAudioPlayer()) {
        self.audioPlayer = audioPlayer
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

struct GreetingsView: View {
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
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.voices) { voice in
                        VoiceButtonView(voice: voice, selectedVoice: $viewModel.selectedVoice) {
                            viewModel.selectVoice(voice)
                            playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                NavigationLink(
                    destination: {
                        if let selectedVoice = viewModel.selectedVoice {
                            ConversationsView(voiceOption: selectedVoice)
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
            }
            .padding()
            .onDisappear {
                viewModel.pauseAudio()
            }
        }
    }
}

struct VoiceButtonView: View {
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
        return voice.voiceId % 2 == 1 ? Color.borderPink : Color.borderOrange
    }
    
    private func bgColor() -> Color {
        return voice.voiceId % 2 == 1 ? Color.bgPink : Color.bgOrange
    }
    
    private func circleImage(_ isFillCircle: Bool) -> String {
        return isFillCircle ? "largecircle.fill.circle" : "circle"
    }
}

#Preview {
    GreetingsView()
}
