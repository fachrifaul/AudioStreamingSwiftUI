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
    private let authEndpoint = URL(string: "https://api-dev.asah.dev/users/verify")!
    private let voicesEndpoint = URL(string: "https://static.dailyfriend.ai/api/greetings")!
    private let speechEndpoint = URL(string: "https://api-dev.asah.dev/conversations/onboarding/speech")!
    
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
            let token = try await getValidJWTToken()
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
    
    func fetchSpeech(
        voiceId: Int,
        onTranscription: @escaping ([AnyHashable : Any]) -> Void
    ) {
        Task {
            do {
                let token = try await getValidJWTToken()
                var request = URLRequest(url: speechEndpoint)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "voice_id": voiceId,
                    "step_id": 1,
                    "audio_format": "pcm"
                ]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

                let (stream, response) = try await URLSession.shared.bytes(for: request)
                
                if let headers = response as? HTTPURLResponse {
                    onTranscription(headers.allHeaderFields)
                }
                
                var buffer = Data()
                
                for try await byte in stream {
                    buffer.append(byte)
                    
                    // Process in chunks of 4096 bytes
                    if buffer.count >= 4096 {
                        let chunk = buffer.prefix(4096) // Extract chunk
                        buffer.removeFirst(4096) // Remove from buffer
                        //await processAudioChunk(chunk)
                    }
                }
                
                // Process any remaining data
                if !buffer.isEmpty {
                    //await processAudioChunk(buffer)
                }
                
            } catch {
                print("Streaming failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Ensures a valid JWT token is available, refreshing if needed
    func getValidJWTToken() async throws -> String {
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
        request.addValue("Bearer ANONYMOUS\(UUID())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw BaseError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let token = json?["id_token"] as? String else {
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
