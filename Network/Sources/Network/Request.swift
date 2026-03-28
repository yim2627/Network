//
//  Request.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public protocol Request {
  var baseURL: String { get }
  var path: String { get }
  var method: HTTPMethod { get }
  var headers: [String: String]? { get }
  var queryItems: [URLQueryItem]? { get }
  var body: (any Encodable)? { get }
  var timeoutInterval: TimeInterval? { get }
}

extension Request {
  public var headers: [String: String]? { nil }
  public var queryItems: [URLQueryItem]? { nil }
  public var body: (any Encodable)? { nil }
  public var timeoutInterval: TimeInterval? { nil }
}
