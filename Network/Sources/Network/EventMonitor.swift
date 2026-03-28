//
//  EventMonitor.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public protocol EventMonitor: Sendable {
  func requestDidStart(_ request: URLRequest)
  func requestDidFinish(
    _ request: URLRequest,
    response: HTTPURLResponse,
    data: Data,
    duration: TimeInterval
  )
  func requestDidFail(
    _ request: URLRequest,
    error: Network.Error,
    duration: TimeInterval
  )
}

extension EventMonitor {
  public func requestDidStart(_ request: URLRequest) {}
  public func requestDidFinish(
    _ request: URLRequest,
    response: HTTPURLResponse,
    data: Data,
    duration: TimeInterval
  ) {}
  public func requestDidFail(
    _ request: URLRequest,
    error: Network.Error,
    duration: TimeInterval
  ) {}
}
