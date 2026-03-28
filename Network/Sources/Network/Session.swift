//
//  Session.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public protocol Session: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: Session {}
