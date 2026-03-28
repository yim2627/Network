//
//  NetworkConfiguration.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public struct NetworkConfiguration: Sendable {
  public let baseURL: String
  public let defaultHeaders: [String: String]
  public let timeoutInterval: TimeInterval
  public let encoder: JSONEncoder
  public let decoder: JSONDecoder
  public let maxRetryCount: Int

  public init(
    baseURL: String,
    defaultHeaders: [String: String] = ["Content-Type": "application/json"],
    timeoutInterval: TimeInterval = 30,
    maxRetryCount: Int = 3,
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.baseURL = baseURL
    self.defaultHeaders = defaultHeaders
    self.timeoutInterval = timeoutInterval
    self.maxRetryCount = maxRetryCount
    self.encoder = encoder
    self.decoder = decoder
  }
}
