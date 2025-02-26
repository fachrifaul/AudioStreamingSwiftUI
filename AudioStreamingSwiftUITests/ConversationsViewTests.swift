//
//  AudioStreamingSwiftUITests.swift
//  AudioStreamingSwiftUITests
//
//  Created by Fachri Febrian on 26/02/2025.
//

import XCTest
@testable import AudioStreamingSwiftUI

final class ConversationsViewTests: XCTestCase {
    
    func testFetchText_Success() {
        let mockText = "Hello, this is a test transcript."
        let mockURLSession = MockURLSession(data: mockText.data(using: .utf8), response: nil, error: nil)
        let viewModel = ConversationsViewModel(urlSession: mockURLSession)
        
        viewModel.fetch(
            textURL: URL(string: "https://example.com/transcription.txt")!,
            audioURL: URL(string: "https://example.com/audio.mp3")!
        )
        
        // Wait for async operation
        let expectation = XCTestExpectation(description: "Fetch text")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(viewModel.text, mockText)
            XCTAssertNil(viewModel.errorMessage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchText_Failure() {
        let mockError = NSError(domain: "TestError", code: 1, userInfo: nil)
        let mockURLSession = MockURLSession(data: nil, response: nil, error: mockError)
        let viewModel = ConversationsViewModel(urlSession: mockURLSession)
        
        viewModel.fetch(
            textURL: URL(string: "https://example.com/transcription.txt")!,
            audioURL: URL(string: "https://example.com/audio.mp3")!
        )
        
        let expectation = XCTestExpectation(description: "Fetch text")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(viewModel.text)
            XCTAssertEqual(viewModel.errorMessage, "Failed to load text: \(mockError.localizedDescription)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
