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
    func playStream(voiceId: Int,
                    stepId: Int,token: String, onTranscription: @escaping ([AnyHashable : Any]) -> Void, onComplete: @escaping () -> Void)
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
    func playStream(voiceId: Int,
                    stepId: Int, token: String, onTranscription: @escaping ([AnyHashable : Any]) -> Void, onComplete: @escaping () -> Void) {}
    
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
    
    func playStream(voiceId: Int,
                    stepId: Int, token: String, onTranscription: @escaping ([AnyHashable : Any]) -> Void, onComplete: @escaping () -> Void) {}
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
    }
}

class AudioPlayerQueue: AudioPlayerProtocol {
    private var audioQueue: AudioQueueRef?
    private var audioFormat = AudioStreamBasicDescription()
    private var buffers: [AudioQueueBufferRef?] = Array(repeating: nil, count: 3)
    private var audioData: Data?
    private var dataOffset: Int = 0
    private var isPaused = false
    
    init(sampleRate: Double = 16000, channels: UInt32 = 1) {
        // Set up format
        audioFormat.mSampleRate = sampleRate
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        audioFormat.mBytesPerPacket = 2 * channels
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerFrame = 2 * channels
        audioFormat.mChannelsPerFrame = channels
        audioFormat.mBitsPerChannel = 16
        
        // Create Audio Queue
        let status = AudioQueueNewOutput(&audioFormat, audioQueueCallback, Unmanaged.passUnretained(self).toOpaque(), nil, nil, 0, &audioQueue)
        
        if status != noErr {
            print("AudioQueueNewOutput failed with status: \(status)")
            audioQueue = nil
        }
    }
    
    func play(urlString: String) {
        guard let url = URL(string: "https://api-dev.asah.dev/conversations/onboarding/speech") else {
//        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        playDownload(url: url)
    }
    
    private func playDownload(url: URL){
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
                await audioStart(data: data)
            } catch {
                print("Failed to load data: \(error.localizedDescription)")
            }
        }
    }
    
    func playStream(
        voiceId: Int,
        stepId: Int,
        token: String,
        onTranscription: @escaping ([AnyHashable : Any]) -> Void,
        onComplete: @escaping () -> Void
    ) {
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api-dev.asah.dev/conversations/onboarding/speech")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "voice_id": voiceId,
                    "step_id": stepId,
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
                    if buffer.count >= 512 {
                        let chunk = buffer.prefix(512) // Extract chunk
                        buffer.removeFirst(512) // Remove from buffer
                        await processAudioChunk(chunk)
                    }
                }
                
                // Process any remaining data
                if !buffer.isEmpty {
                    await processAudioChunk(buffer)
                    //onComplete()
                }
                
            } catch {
                print("Streaming failed: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func audioStart(data: Data) {
        self.audioData = data
        self.dataOffset = 0
        self.isPaused = false
        
        guard let queue = self.audioQueue else {
            print("Error: AudioQueue is nil")
            return
        }
        
        // Allocate and enqueue buffers
        for i in 0..<self.buffers.count {
            let status = AudioQueueAllocateBuffer(queue, 512, &self.buffers[i])
            if status != noErr {
                print("AudioQueueAllocateBuffer failed for buffer \(i) with status: \(status)")
            } else {
                self.enqueueBuffer(self.buffers[i]!)
            }
        }
        
        // Start playback
        AudioQueueStart(queue, nil)
    }
    
    @MainActor
    private func processAudioChunk(_ chunk: Data) {
        guard let queue = audioQueue else { return }
        
        var buffer: AudioQueueBufferRef?
        
        AudioQueueAllocateBuffer(queue, UInt32(chunk.count), &buffer)
        
        if let buffer = buffer {
            buffer.pointee.mAudioDataByteSize = UInt32(chunk.count)
            chunk.copyBytes(to: buffer.pointee.mAudioData.assumingMemoryBound(to: UInt8.self), count: chunk.count)
            
            let status = AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
            if status != noErr {
                print("AudioQueueEnqueueBuffer failed with status: \(status)")
            }
        }
        
        AudioQueueStart(queue, nil)
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
    
    private func enqueueBuffer(_ buffer: AudioQueueBufferRef) {
        guard let audioData = audioData else { return }
        
        let bytesToCopy = min(audioData.count - dataOffset, Int(buffer.pointee.mAudioDataBytesCapacity))
        
        if bytesToCopy > 0 {
            let audioPointer = buffer.pointee.mAudioData.assumingMemoryBound(to: UInt8.self)
            audioData.copyBytes(to: audioPointer, from: dataOffset..<(dataOffset + bytesToCopy))
            buffer.pointee.mAudioDataByteSize = UInt32(bytesToCopy)
            dataOffset += bytesToCopy
            
            AudioQueueEnqueueBuffer(audioQueue!, buffer, 0, nil)
        } else {
            // Stop when no more data
            stop()
        }
    }
    
    private let audioQueueCallback: AudioQueueOutputCallback = { userData, queue, buffer in
        let player = Unmanaged<AudioPlayerQueue>.fromOpaque(userData!).takeUnretainedValue()
        player.enqueueBuffer(buffer)
    }
    
//    func audioQueueStopped
//    private let audioQueueStopped: AudioQueueOutputCallback = { userData, audioQueue, propertyID in
//        if propertyID == kAudioQueueProperty_IsRunning {
//            var isRunning: UInt32 = 0
//            var size = UInt32(MemoryLayout<UInt32>.size)
//            AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &size)
//            
//            if isRunning == 0 {
//                print("🔊 Audio queue finished playing.")
//                DispatchQueue.main.async {
//                    //self.fetchNextAudio() // Start the next step
//                }
//            }
//        }
//    }
}
