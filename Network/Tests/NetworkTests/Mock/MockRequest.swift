//
//  MockRequest.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Foundation
@testable import Network

struct MockRequest: Request {
  var baseURL: String = "https://api.example.com"
  var path: String = "users"
  var method: HTTPMethod = .get
  var headers: [String: String]?
  var queryItems: [URLQueryItem]?
  var body: (any Encodable)?
  var timeoutInterval: TimeInterval?
}
