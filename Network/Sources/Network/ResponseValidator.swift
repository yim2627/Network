//
//  ResponseValidator.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

struct ResponseValidator {
  func validate(_ response: URLResponse, data: Data) throws(Network.Error) {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw .response(.invalidHTTPResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return
    case 400:
      throw .response(.badRequest(data))
    case 401:
      throw .response(.unauthorized)
    case 403:
      throw .response(.forbidden)
    case 404:
      throw .response(.notFound)
    case 500:
      throw .response(.internalServerError)
    case 503:
      throw .response(.serviceUnavailable)
    case 500...599:
      throw .response(.serverError(statusCode: httpResponse.statusCode))
    default:
      throw .response(.unexpectedStatusCode(statusCode: httpResponse.statusCode))
    }
  }
}
