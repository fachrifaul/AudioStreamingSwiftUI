//
//  GreetingsUseCase.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 28/03/2025.
//

actor VoicesUseCase {
    nonisolated(unsafe) final var repository: VoicesRepositoryEntity
    
    init(repository: VoicesRepositoryEntity = VoicesRepository()) {
        self.repository = repository
    }
    
    func call() async -> Result<[VoiceOption], BaseError> {
        return await repository.greetings()
    }
}
