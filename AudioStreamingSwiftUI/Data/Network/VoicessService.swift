//
//  GreetingsService.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 28/03/2025.
//
import Foundation

class GreetingsService {
    private let voicesEndpoint = URL(string: "https://static.dailyfriend.ai/api/greetings")!
    
    private nonisolated(unsafe) var urlSession: URLSessionProtocol
    
    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    func fetchGreetings(body: [String: Any]) async -> Result<[VoiceOption], BaseError> {
        do {
            //            let token = try await getValidJWTToken()
            
            var request = URLRequest(url: voicesEndpoint)
            //            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.invalidResponse)
            }
            
            let voices = try JSONDecoder().decode([VoiceOption].self, from: data)
            return .success(voices)
        } catch {
            return .failure(.networkError(error))
        }
    }
}
