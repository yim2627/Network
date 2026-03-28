//
//  MockSession.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Foundation
@testable import Network

final class MockSession: Session, @unchecked Sendable {
  var result: (Data, URLResponse)?
  var error: Swift.Error?
  var requestedURLRequests: [URLRequest] = []

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    requestedURLRequests.append(request)

    if let error {
      throw error
    }

    guard let result else {
      throw URLError(.unknown)
    }

    return result
  }
}

// MARK: - Helpers

extension MockSession {
  static func success(
    data: Data = Data(),
    statusCode: Int = 200,
    url: URL = URL(string: "https://api.example.com")!
  ) -> MockSession {
    let session = MockSession()
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: nil
    )!
    session.result = (data, response)
    return session
  }

  static func failure(_ error: Swift.Error) -> MockSession {
    let session = MockSession()
    session.error = error
    return session
  }
}
