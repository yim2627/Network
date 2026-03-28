//
//  Error.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public enum Error: Swift.Error {
  case config(Config)
  case interceptor(Interceptor)
  case session(Session)
  case decode(Decode)
  case encode(Encode)
  case response(Response)
  case unknown(Swift.Error?)
}

// MARK: - Config

extension Error {
  public enum Config: Swift.Error {
    case invalidBaseURL
    case invalidPath
    case invalidQueryItems
    case invalidURL
  }
}

// MARK: - Interceptor

extension Error {
  public enum Interceptor: Swift.Error {
    case adapt(Swift.Error)
    case retry(Swift.Error)
    case maxRetryExceeded(Int)
  }
}

// MARK: - Session

extension Error {
  public enum Session: Swift.Error {
    case notConnected
    case timeout
    case cancelled
    case dnsLookupFailed
    case sslFailed
    case underlying(URLError)
  }
}

// MARK: - Decode

extension Error {
  public enum Decode: Swift.Error {
    case noData
    case invalidData(DecodingError?)
  }
}

// MARK: - Encode

extension Error {
  public enum Encode: Swift.Error {
    case noEncodable
    case invalidData(EncodingError?)
  }
}

// MARK: - Response

extension Error {
  public enum Response: Swift.Error {
    case invalidHTTPResponse
    case badRequest(Data?) // 400
    case unauthorized // 401
    case forbidden // // 403
    case notFound // 404
    case internalServerError // 500
		case serviceUnavailable // 503
    case serverError(statusCode: Int) // 50x
		case unexpectedStatusCode(statusCode: Int)
  }
}
