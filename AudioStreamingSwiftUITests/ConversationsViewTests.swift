//
//  AudioStreamingSwiftUITests.swift
//  AudioStreamingSwiftUITests
//
//  Created by Fachri Febrian on 26/02/2025.
//

import XCTest
@testable import AudioStreamingSwiftUI

final class ConversationsViewTests: XCTestCase {
    
    func testFetchText_Success() async {
        let mockText = "Hello, this is a test transcript."
        let response = HTTPURLResponse(
            url: URL(string: "https://static.dailyfriend.ai/conversations/samples/1/2/transcription.txt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let mockURLSession = MockURLSession(data: mockText.data(using: .utf8), response: response, error: nil)
        let viewModel = ConversationsViewModel(
            voiceOption: VoiceOption(voiceId: 1, sampleId: 1, name: "Stone"), 
            api: API(urlSession: mockURLSession)
        )
        
        let expectation = expectation(description: "Fetch text successfully")
        
        Task {
            await viewModel.fetch(randomSampleId: 2)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Wait for async operation
        XCTAssertEqual(viewModel.text, mockText)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchText_Failure() async {
        let mockError = NSError(domain: "TestError", code: 1, userInfo: nil)
        let mockURLSession = MockURLSession(data: nil, response: nil, error: mockError)
        let viewModel = ConversationsViewModel(
            voiceOption: VoiceOption(voiceId: 1, sampleId: 1, name: "Stone"),
            api: API(urlSession: mockURLSession)
        )
        
        let expectation = expectation(description: "Fetch text failure")
        
        Task {
            await viewModel.fetch()
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNil(viewModel.text)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
