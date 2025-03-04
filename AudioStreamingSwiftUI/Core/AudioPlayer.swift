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
    func play(urlString: String)
    func playStream(body: [String: Any],
                    onTranscription: @escaping ([AnyHashable : Any]) -> Void,
                    onComplete: @escaping () -> Void) async
    func pause()
    func stop()
}

class AVAudioPlayer: AudioPlayerProtocol {
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
    func playStream(body: [String: Any],
                    onTranscription: @escaping ([AnyHashable : Any]) -> Void,
                    onComplete: @escaping () -> Void) { }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }
}

class AudioPlayerStreaming: AudioPlayerProtocol {
    private var player: AudioPlayer?
    
    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        player = AudioPlayer()
        player?.play(url: url)
    }
    
    func playStream(body: [String: Any],
                    onTranscription: @escaping ([AnyHashable : Any]) -> Void,
                    onComplete: @escaping () -> Void) { }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
    }
}

class AudioPlayerQueue: AudioPlayerProtocol {
    private var api: API
    
    private var audioQueue: AudioQueueRef?
    private var audioFormat = AudioStreamBasicDescription()
    private var buffers: [AudioQueueBufferRef?] = Array(repeating: nil, count: 3)
    private var audioData: Data?
    private var dataOffset: Int = 0
    private var isPaused = false
    private var activeBufferCount = 0  // Track active buffers
    private var onCompleteCallback: (() -> Void)?
    
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
        playDownload(url: url)
    }
    
    private func playDownload(url: URL){
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
                await initializeAudioQueue()
                print("Downloaded audio data size: \(data.count) bytes")
                await processAudioData(data)
            } catch {
                print("Failed to load data: \(error.localizedDescription)")
            }
        }
    }
    
    func playStream(
        body: [String: Any],
        onTranscription: @escaping ([AnyHashable: Any]) -> Void,
        onComplete: @escaping () -> Void
    ) async {
        self.onCompleteCallback = onComplete
        
        Task {
            do {
                let token = try await api.getValidJWTToken()
                var request = URLRequest(url: api.speechEndpoint)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                
                let (stream, response) = try await URLSession.shared.bytes(for: request)
                
                if let headers = response as? HTTPURLResponse {
                    onTranscription(headers.allHeaderFields)
                }
                
                // Initialize the audio queue
                await initializeAudioQueue()
                
                var buffer = Data()
                
                for try await byte in stream {
                    buffer.append(byte)
                    
                    // Process in chunks
                    if buffer.count >= 512 {
                        let chunk = buffer.prefix(512)
                        buffer.removeFirst(512)
                        await processAudioData(chunk)
                    }
                }
                
                // Process remaining data
                if !buffer.isEmpty {
                    await processAudioData(buffer)
                }
                
            } catch {
                print("Streaming failed: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func initializeAudioQueue() {
        let callback: AudioQueueOutputCallback = { userData, queue, buffer in
            let audioPlayer = Unmanaged<AudioPlayerQueue>.fromOpaque(userData!).takeUnretainedValue()
            
            audioPlayer.activeBufferCount -= 1
            print("Buffer finished playing. Active buffers: \(audioPlayer.activeBufferCount)")
            
            if audioPlayer.activeBufferCount == 0 {
                print("🔊 Audio queue finished playing all buffers.")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    audioPlayer.onCompleteCallback?()
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
    
    @MainActor
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
}
