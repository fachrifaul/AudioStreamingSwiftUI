//
//  VoiceOption.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import Foundation

struct VoiceOption: Identifiable, Decodable {
    enum CodingKeys: String, CodingKey {
        case id, voiceId, sampleId, name
    }
    
    var id = UUID()
    let voiceId: Int
    let sampleId: Int
    let name: String
    
    var imageUrlString: String {
        return "https://static.dailyfriend.ai/images/voices/\(name.lowercased()).svg"
    }
    
    var soundUrlString: String {
        return "https://static.dailyfriend.ai/conversations/samples/\(voiceId)/\(sampleId)/audio.mp3"
    }
}
