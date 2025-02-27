//
//  API.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 27/02/2025.
//

import Foundation

//
//  API.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 27/02/2025.
//

import Foundation

class API {
    private let authEndpoint = URL(string: "https://static.dailyfriend.ai/api/auth")!
    private let voicesEndpoint = URL(string: "https://static.dailyfriend.ai/api/greetings")!
    
    static func soundUrlString(voiceId: Int, sampleId: Int) ->  String {
        return "https://static.dailyfriend.ai/conversations/samples/\(voiceId)/\(sampleId)/audio.mp3"
    }
    
    private var urlSession: URLSessionProtocol
    
    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    func fetchGreetings() async -> Result<[VoiceOption], BaseError> {
        do {
//            let token = try await getValidJWTToken()
            
            var request = URLRequest(url: voicesEndpoint)
//            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
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
    
    func fetchTransciption(voiceId: Int, sampleId: Int) async -> Result<String, BaseError> {
        do {
//            let token = try await getValidJWTToken()
            let urlString = "https://static.dailyfriend.ai/conversations/samples/\(voiceId)/\(sampleId)/transcription.txt"
            guard let url = URL(string: urlString) else {
                return .failure(.errorUrl)
            }
            var request = URLRequest(url: url)
//            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.invalidResponse)
            }
            
            if let fetchedText = String(data: data, encoding: .utf8) {
                return .success(fetchedText)
            } else {
                return .failure(.failedDecoded)
            }
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    /// Ensures a valid JWT token is available, refreshing if needed
    private func getValidJWTToken() async throws -> String {
        if let token = getJWTToken() {
            return token
        }
        return try await fetchJWTToken()
    }
    
    /// Fetches a new JWT token from the authentication endpoint
    private func fetchJWTToken() async throws -> String {
        var request = URLRequest(url: authEndpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": "your_username", "password": "your_password"] // Change based on API
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw BaseError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let token = json?["token"] as? String else {
            throw BaseError.missingToken
        }
        
        storeJWTToken(token)
        return token
    }
    
    /// Stores JWT token securely
    private func storeJWTToken(_ token: String) {
        UserDefaults.standard.setValue(token, forKey: "jwt_token") // Use Keychain for production
    }
    
    /// Retrieves JWT token
    private func getJWTToken() -> String? {
        return UserDefaults.standard.string(forKey: "jwt_token")
    }
}

enum BaseError: Error {
    case missingToken
    case invalidResponse
    case failedDecoded
    case errorUrl
    case networkError(Error)
}
