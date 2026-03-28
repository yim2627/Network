//
//  ResponseValidatorTests.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Testing
import Foundation
@testable import Network

@Suite("ResponseValidator 테스트")
struct ResponseValidatorTests {
  let sut = ResponseValidator()
  let url = URL(string: "https://api.example.com")!
  let data = Data()

  private func httpResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
  }

  // MARK: - 성공

  @Test("200~299_상태코드면_에러가_발생하지_않는다", arguments: [200, 201, 204, 299])
  func 성공_상태코드면_에러가_발생하지_않는다(statusCode: Int) throws {
    try sut.validate(httpResponse(statusCode: statusCode), data: data)
  }

  // MARK: - 4xx 에러

  @Test("400이면_badRequest_에러가_발생한다")
  func 상태코드_400이면_badRequest_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 400), data: data)
    }
  }

  @Test("401이면_unauthorized_에러가_발생한다")
  func 상태코드_401이면_unauthorized_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 401), data: data)
    }
  }

  @Test("403이면_forbidden_에러가_발생한다")
  func 상태코드_403이면_forbidden_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 403), data: data)
    }
  }

  @Test("404이면_notFound_에러가_발생한다")
  func 상태코드_404이면_notFound_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 404), data: data)
    }
  }

  // MARK: - 5xx 에러

  @Test("500이면_internalServerError_에러가_발생한다")
  func 상태코드_500이면_internalServerError_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 500), data: data)
    }
  }

  @Test("503이면_serviceUnavailable_에러가_발생한다")
  func 상태코드_503이면_serviceUnavailable_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 503), data: data)
    }
  }

  @Test("502이면_serverError_에러가_발생한다")
  func 상태코드_502이면_serverError_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 502), data: data)
    }
  }

  // MARK: - 기타

  @Test("예상하지_못한_상태코드면_unexpectedStatusCode_에러가_발생한다")
  func 예상하지_못한_상태코드면_unexpectedStatusCode_에러가_발생한다() {
    #expect(throws: Network.Error.self) {
      try sut.validate(httpResponse(statusCode: 302), data: data)
    }
  }

  @Test("HTTPURLResponse가_아니면_invalidHTTPResponse_에러가_발생한다")
  func HTTPURLResponse가_아니면_invalidHTTPResponse_에러가_발생한다() {
    let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    #expect(throws: Network.Error.self) {
      try sut.validate(response, data: data)
    }
  }
}
