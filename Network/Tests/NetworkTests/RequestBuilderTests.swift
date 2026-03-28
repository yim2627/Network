//
//  RequestBuilderTests.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Testing
import Foundation
@testable import Network

@Suite("RequestBuilder 테스트")
struct RequestBuilderTests {
  let configuration = NetworkConfiguration(baseURL: "https://api.example.com")
  var sut: RequestBuilder { RequestBuilder(configuration: configuration) }

  // MARK: - URL 구성

  @Test("유효한_Request를_전달하면_올바른_URL이_생성된다")
  func 유효한_Request를_전달하면_올바른_URL이_생성된다() throws {
    let request = MockRequest(baseURL: "https://api.example.com", path: "users")
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.url?.absoluteString == "https://api.example.com/users")
  }

  @Test("path에_슬래시가_없으면_자동으로_추가된다")
  func path에_슬래시가_없으면_자동으로_추가된다() throws {
    let request = MockRequest(baseURL: "https://api.example.com", path: "users/1")
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.url?.absoluteString == "https://api.example.com/users/1")
  }

  @Test("queryItems를_전달하면_URL에_쿼리가_추가된다")
  func queryItems를_전달하면_URL에_쿼리가_추가된다() throws {
    var request = MockRequest()
    request.queryItems = [
      URLQueryItem(name: "page", value: "1"),
      URLQueryItem(name: "limit", value: "20"),
    ]
    let urlRequest = try sut.build(from: request)
    let components = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)!
    #expect(components.queryItems?.count == 2)
    #expect(components.queryItems?.first(where: { $0.name == "page" })?.value == "1")
  }

  // MARK: - Method & Headers

  @Test("httpMethod가_올바르게_설정된다")
  func httpMethod가_올바르게_설정된다() throws {
    var request = MockRequest(method: .post)
    request.body = ["key": "value"]
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.httpMethod == "POST")
  }

  @Test("기본_헤더와_Request_헤더가_합쳐지고_Request_헤더가_우선한다")
  func 기본_헤더와_Request_헤더가_합쳐진다() throws {
    let config = NetworkConfiguration(
      baseURL: "https://api.example.com",
      defaultHeaders: ["Content-Type": "application/json", "Accept": "application/json"]
    )
    let builder = RequestBuilder(configuration: config)
    var request = MockRequest()
    request.headers = ["Content-Type": "text/plain", "Authorization": "Bearer token"]
    let urlRequest = try builder.build(from: request)

    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "text/plain")
    #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
  }

  @Test("timeoutInterval이_설정되면_해당_값이_사용된다")
  func timeoutInterval이_설정되면_해당_값이_사용된다() throws {
    var request = MockRequest()
    request.timeoutInterval = 60
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.timeoutInterval == 60)
  }

  @Test("timeoutInterval이_nil이면_configuration_기본값이_사용된다")
  func timeoutInterval이_nil이면_기본값이_사용된다() throws {
    let request = MockRequest()
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.timeoutInterval == configuration.timeoutInterval)
  }

  // MARK: - Body 인코딩

  @Test("body가_있으면_JSON으로_인코딩된다")
  func body가_있으면_JSON으로_인코딩된다() throws {
    var request = MockRequest(method: .post)
    request.body = ["name": "test"]
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.httpBody != nil)

    let decoded = try JSONDecoder().decode([String: String].self, from: urlRequest.httpBody!)
    #expect(decoded["name"] == "test")
  }

  // MARK: - Config 에러

  @Test("잘못된_baseURL을_전달하면_invalidBaseURL_에러가_발생한다")
  func 잘못된_baseURL을_전달하면_invalidBaseURL_에러가_발생한다() {
    let request = MockRequest(baseURL: "ht tp://invalid url")
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  @Test("path에_공백이_포함되면_invalidPath_에러가_발생한다")
  func path에_공백이_포함되면_invalidPath_에러가_발생한다() {
    let request = MockRequest(path: "invalid path")
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  @Test("path에_개행이_포함되면_invalidPath_에러가_발생한다")
  func path에_개행이_포함되면_invalidPath_에러가_발생한다() {
    let request = MockRequest(path: "invalid\npath")
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  @Test("queryItem의_name이_비어있으면_invalidQueryItems_에러가_발생한다")
  func queryItem의_name이_비어있으면_invalidQueryItems_에러가_발생한다() {
    var request = MockRequest()
    request.queryItems = [URLQueryItem(name: "", value: "value")]
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  // MARK: - Encode 에러

  @Test("POST인데_body가_nil이면_noEncodable_에러가_발생한다")
  func POST인데_body가_nil이면_noEncodable_에러가_발생한다() {
    let request = MockRequest(method: .post)
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  @Test("PUT인데_body가_nil이면_noEncodable_에러가_발생한다")
  func PUT인데_body가_nil이면_noEncodable_에러가_발생한다() {
    let request = MockRequest(method: .put)
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  @Test("PATCH인데_body가_nil이면_noEncodable_에러가_발생한다")
  func PATCH인데_body가_nil이면_noEncodable_에러가_발생한다() {
    let request = MockRequest(method: .patch)
    #expect(throws: Network.Error.self) {
      try sut.build(from: request)
    }
  }

  @Test("GET이면_body가_nil이어도_에러가_발생하지_않는다")
  func GET이면_body가_nil이어도_에러가_발생하지_않는다() throws {
    let request = MockRequest(method: .get)
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.httpBody == nil)
  }

  @Test("DELETE이면_body가_nil이어도_에러가_발생하지_않는다")
  func DELETE이면_body가_nil이어도_에러가_발생하지_않는다() throws {
    let request = MockRequest(method: .delete)
    let urlRequest = try sut.build(from: request)
    #expect(urlRequest.httpBody == nil)
  }
}
