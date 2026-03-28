//
//  RequestBuilder.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

struct RequestBuilder {
  private let configuration: NetworkConfiguration

  init(configuration: NetworkConfiguration) {
    self.configuration = configuration
  }

  func build(from request: Request) throws(Network.Error) -> URLRequest {
    let url = try makeURL(from: request)
    var urlRequest = URLRequest(url: url)

    urlRequest.httpMethod = request.method.rawValue
    urlRequest.timeoutInterval = request.timeoutInterval ?? configuration.timeoutInterval

    // 기본 헤더 + Request 헤더 (Request 헤더가 우선)
    configuration.defaultHeaders.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
    request.headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

    // Body 인코딩
    let requiresBody = request.method == .post || request.method == .put || request.method == .patch
    if let body = request.body {
      do {
        urlRequest.httpBody = try configuration.encoder.encode(body)
      } catch let error as EncodingError {
        throw .encode(.invalidData(error))
      } catch {
        throw .encode(.invalidData(nil))
      }
    } else if requiresBody {
      throw .encode(.noEncodable)
    }

    return urlRequest
  }
}

// MARK: - Private

extension RequestBuilder {
  private func makeURL(from request: Request) throws(Network.Error) -> URL {
    let baseURLString = request.baseURL

    guard var components = URLComponents(string: baseURLString) else {
      throw .config(.invalidBaseURL)
    }

    // path 검증: 공백·제어문자 등 URL에 들어갈 수 없는 문자 포함 여부
    guard request.path.allSatisfy({ !$0.isNewline && $0 != " " }) else {
      throw .config(.invalidPath)
    }

    components.path = components.path.hasSuffix("/")
      ? components.path + request.path
      : components.path + "/" + request.path

    if let queryItems = request.queryItems {
      // queryItems 검증: name이 비어있는 항목이 있으면 실패
      guard queryItems.allSatisfy({ !$0.name.isEmpty }) else {
        throw .config(.invalidQueryItems)
      }
      components.queryItems = (components.queryItems ?? []) + queryItems
    }

    guard let url = components.url else {
      throw .config(.invalidURL)
    }

    return url
  }
}
