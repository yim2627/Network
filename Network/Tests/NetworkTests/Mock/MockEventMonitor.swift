//
//  MockEventMonitor.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Foundation
@testable import Network

final class MockEventMonitor: EventMonitor, @unchecked Sendable {
  var didStartRequests: [URLRequest] = []
  var didFinishResults: [(URLRequest, HTTPURLResponse, Data)] = []
  var didFailResults: [(URLRequest, Network.Error, TimeInterval)] = []

  func requestDidStart(_ request: URLRequest) {
    didStartRequests.append(request)
  }

  func requestDidFinish(
    _ request: URLRequest,
    response: HTTPURLResponse,
    data: Data,
    duration: TimeInterval
  ) {
    didFinishResults.append((request, response, data))
  }

  func requestDidFail(
    _ request: URLRequest,
    error: Network.Error,
    duration: TimeInterval
  ) {
    didFailResults.append((request, error, duration))
  }
}
