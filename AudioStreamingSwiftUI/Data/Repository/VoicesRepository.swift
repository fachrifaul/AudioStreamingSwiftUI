//
//  VoicesRepository.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 28/03/2025.
//

protocol VoicesRepositoryEntity {
    func greetings() async -> Result<[VoiceOption], BaseError>
}

actor VoicesRepository: VoicesRepositoryEntity {
    final let service: GreetingsService
    
    init(service: GreetingsService = GreetingsService()) {
        self.service = service
    }
    
    func greetings() async -> Result<[VoiceOption], BaseError> {
        //return await service.fetchGreetings()
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let voices = [
                VoiceOption(voiceId: 1, sampleId: 1, name: "Meadow"),
                VoiceOption(voiceId: 2, sampleId: 1, name: "Cypress"),
                VoiceOption(voiceId: 3, sampleId: 1, name: "Iris"),
                VoiceOption(voiceId: 4, sampleId: 1, name: "Hawke"),
                VoiceOption(voiceId: 5, sampleId: 1, name: "Seren"),
                VoiceOption(voiceId: 6, sampleId: 1, name: "Stone")
            ]
            
            return .success(voices)
        } catch {
            return .failure(.networkError(error))
        }
    }
}
