//
//  MockURLSession.swift
//  AudioStreamingSwiftUITests
//
//  Created by Fachri Febrian on 26/02/2025.
//

import Foundation
@testable import AudioStreamingSwiftUI

class MockURLSession: URLSessionProtocol {
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?

    init(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }

    func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        return MockURLSessionDataTask {
            completionHandler(self.data, self.response, self.error)
        }
    }
}

class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    func resume() {
        closure()
    }
}

