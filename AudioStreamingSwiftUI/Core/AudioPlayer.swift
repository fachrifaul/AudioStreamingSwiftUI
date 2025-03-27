//
//  AudioPlayerProtocol.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import AudioToolbox
import AVFoundation
import AudioStreaming
import Foundation
import SwiftUI

protocol AudioPlayerProtocol {
    var delegate: AudioPlayerDelegate? { get set }
    
    func play(urlString: String)
    func playStream(body: [String: Any], stepId: Int)
    func pause()
    func stop()
}

extension AudioPlayerProtocol {
    
    func play(urlString: String) {
        // Default implementation (empty, making it "optional")
    }
    
    func playStream(body: [String: Any], stepId: Int)  {
        // Default implementation (empty, making it "optional")
    }
}

class AVAudioPlayer: AudioPlayerProtocol {
    public weak var delegate: AudioPlayerDelegate?
    private var player: AVPlayer?
    
    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global(qos: .background).async {
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            DispatchQueue.main.async {
                self.player = AVPlayer(playerItem: playerItem)
                self.player?.play()
            }
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }
}

class AudioPlayerStreaming: AudioPlayerProtocol {
    public weak var delegate: AudioPlayerDelegate?
    
    private var player: AudioPlayer?
    
    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        player = AudioPlayer()
        player?.play(url: url)
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
    }
}

public protocol AudioPlayerDelegate: AnyObject {
    func onTranscription(headers: ([AnyHashable : Any]))
    func complete(stepId: Int)
}

class AudioPlayerQueue: AudioPlayerProtocol, @unchecked Sendable {
    private var api: API
    
    private var audioQueue: AudioQueueRef?
    private var audioFormat = AudioStreamBasicDescription()
    private var buffers: [AudioQueueBufferRef?] = Array(repeating: nil, count: 3)
    private var audioData: Data?
    private var dataOffset: Int = 0
    private var isPaused = false
    private var activeBufferCount = 0  // Track active buffers
    
    public weak var delegate: AudioPlayerDelegate?
    var stepId: Int = 0
    
    
    init(
        api: API,
        sampleRate: Double = 16000,
        channels: UInt32 = 1
    ) {
        self.api = api
        // Set up format
        audioFormat.mSampleRate = sampleRate
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        audioFormat.mBytesPerPacket = 2 * channels
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerFrame = 2 * channels
        audioFormat.mChannelsPerFrame = channels
        audioFormat.mBitsPerChannel = 16
    }
    
    func play(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
//        playDownload(url: url)
    }
    
    private func playDownload(url: URL)  {
//        do {
//            let (data, _) = try  URLSession.shared.data(for: URLRequest(url: url))
//            initializeAudioQueue()
//            print("Downloaded audio data size: \(data.count) bytes")
//            processAudioData(data)
//        } catch {
//            print("Failed to load data: \(error.localizedDescription)")
//        }
        URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            if let error = error {
                print("Failed to load data: \(error.localizedDescription)")
                return
            }
            if let data = data {
                self?.initializeAudioQueue()
                print("Downloaded audio data size: \(data.count) bytes")
                self?.processAudioData(data)
            }
        }.resume()
    }
    
    func playStream(body: [String: Any], stepId: Int) {
        self.stepId = stepId
        getValidJWTToken { [weak self] result in
            guard let self = self else { return } // Ensure self exists

            switch result {
            case .success(let token):
                var request = URLRequest(url: URL(string: "https://api-dev.asah.dev/conversations/onboarding/speech")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                } catch {
                    return
                }
                
                
                let task = URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
                    if let error = error {
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.delegate?.onTranscription(headers: httpResponse.allHeaderFields)
                    }
                    
                    // Initialize the audio queue
                    self?.initializeAudioQueue()
                    
                    if let data = data {
                        var buffer = Data()
                        buffer.append(data)
                        
                        // Process in chunks
                        while buffer.count >= 512 {
                            let chunk = buffer.prefix(512)
                            buffer.removeFirst(512)
                            print("Buffer finished playing. finish.")
                            self?.processAudioData(chunk)
                        }
                        
                        // Process remaining data
                        if !buffer.isEmpty {
                            self?.processAudioData(buffer)
                        }
                    }
                    
                    
                }
                task.resume()
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func initializeAudioQueue() {
        let callback: AudioQueueOutputCallback = { userData, queue, buffer in
            let audioPlayer = Unmanaged<AudioPlayerQueue>.fromOpaque(userData!).takeUnretainedValue()
            
            audioPlayer.activeBufferCount -= 1
            print("Buffer finished playing. Active buffers: \(audioPlayer.activeBufferCount)")
            
            if audioPlayer.activeBufferCount == 0 {
                print("🔊 Audio queue finished playing all buffers.")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    //                audioPlayer.onCompleteCallback?()
                    //                audioPlayer.eventContinuation?.yield(EventMessage(key: "finished", value: true))
                    audioPlayer.delegate?.complete(stepId: audioPlayer.stepId)
                }
            }
        }
        
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = AudioQueueNewOutput(
            &audioFormat,
            callback,
            userData,
            nil,
            nil,
            0,
            &audioQueue
        )
        
        if status != noErr {
            print("Failed to create audio queue: \(status)")
            return
        }
    }
    
    private func processAudioData(_ chunk: Data) {
        guard let queue = audioQueue else { return }
        
        var buffer: AudioQueueBufferRef?
        
        AudioQueueAllocateBuffer(queue, UInt32(chunk.count), &buffer)
        
        if let buffer = buffer {
            buffer.pointee.mAudioDataByteSize = UInt32(chunk.count)
            chunk.copyBytes(to: buffer.pointee.mAudioData.assumingMemoryBound(to: UInt8.self), count: chunk.count)
            
            let status = AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
            if status == noErr {
                activeBufferCount += 1  // Increase buffer count
            } else {
                print("AudioQueueEnqueueBuffer failed with status: \(status)")
            }
        }
        
        let startStatus = AudioQueueStart(queue, nil)
        if startStatus != noErr {
            print("AudioQueueStart failed with status: \(startStatus)")
        }
    }
    
    func pause() {
        if let queue = audioQueue, !isPaused {
            AudioQueuePause(queue)
            isPaused = true
        }
    }
    
    func stop() {
        if let queue = audioQueue {
            AudioQueueStop(queue, true)
            AudioQueueDispose(queue, true)
            audioQueue = nil
            audioData = nil
            dataOffset = 0
        }
    }
    
    
    func getValidJWTToken(completion: @escaping (Result<String, Error>) -> Void) {
        if let token = getJWTToken() {
            completion(.success(token))
            return
        }
        fetchJWTToken(completion: completion)
    }

    /// Fetches a new JWT token from the authentication endpoint
    func fetchJWTToken(completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://api-dev.asah.dev/users/verify")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer ANONYMOUS\(UUID())", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                completion(.failure(BaseError.invalidResponse))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["id_token"] as? String {
                    self?.storeJWTToken(token)
                    completion(.success(token))
                } else {
                    completion(.failure(BaseError.missingToken))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
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
