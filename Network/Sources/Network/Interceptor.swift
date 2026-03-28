//
//  Interceptor.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public enum RetryPolicy {
  case doNotRetry
  case retry(after: TimeInterval)
}

public protocol Interceptor: Sendable {
  func adapt(_ request: URLRequest) async throws -> URLRequest
  func retry(
    _ request: URLRequest,
    error: Error,
    attemptCount: Int
  ) async throws -> RetryPolicy
}

extension Interceptor {
  public func adapt(_ request: URLRequest) async throws -> URLRequest {
    request
  }

  public func retry(
    _ request: URLRequest,
    error: Error,
    attemptCount: Int
  ) async throws -> RetryPolicy {
    .doNotRetry
  }
}
