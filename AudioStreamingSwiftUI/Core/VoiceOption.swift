//
//  VoiceOption.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import Foundation

struct VoiceOption: Identifiable {
    let id = UUID()
    let voiceId: Int
    let name: String
    
    var imageUrlString: String {
        return "https://static.dailyfriend.ai/images/voices/\(name.lowercased()).svg"
    }
    
    var soundUrlString: String {
        return "https://static.dailyfriend.ai/conversations/samples/\(voiceId)/\(voiceId)/audio.mp3"
    }
    
    var transcriptionUrlString: String {
        return "https://static.dailyfriend.ai/conversations/samples/\(voiceId)/\(voiceId)/transcription.text"
    }
}
