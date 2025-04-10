//
//  VoiceButtonView.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 28/03/2025.
//

import SwiftUI
import SDWebImageSwiftUI

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

