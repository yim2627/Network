//
//  MockInterceptor.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Foundation
@testable import Network

final class MockInterceptor: Interceptor, @unchecked Sendable {
  var adaptHandler: ((URLRequest) async throws -> URLRequest)?
  var retryHandler: ((URLRequest, Network.Error, Int) async throws -> RetryPolicy)?

  var adaptCallCount = 0
  var retryCallCount = 0

  func adapt(_ request: URLRequest) async throws -> URLRequest {
    adaptCallCount += 1
    if let handler = adaptHandler {
      return try await handler(request)
    }
    return request
  }

  func retry(
    _ request: URLRequest,
    error: Network.Error,
    attemptCount: Int
  ) async throws -> RetryPolicy {
    retryCallCount += 1
    if let handler = retryHandler {
      return try await handler(request, error, attemptCount)
    }
    return .doNotRetry
  }
}
