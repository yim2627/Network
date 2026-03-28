//
//  NetworkClientTests.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Testing
import Foundation
@testable import Network

// MARK: - 테스트용 모델

private struct User: Codable, Equatable {
  let id: Int
  let name: String
}

@Suite("NetworkClient 테스트")
struct NetworkClientTests {
  let configuration = NetworkConfiguration(baseURL: "https://api.example.com")

  private func makeClient(
    session: MockSession,
    interceptors: [any Interceptor] = [],
    eventMonitors: [any EventMonitor] = [],
    maxRetryCount: Int = 3
  ) -> NetworkClient {
    let config = NetworkConfiguration(
      baseURL: "https://api.example.com",
      maxRetryCount: maxRetryCount
    )
    return NetworkClient(
      configuration: config,
      session: session,
      interceptors: interceptors,
      eventMonitors: eventMonitors
    )
  }

  // MARK: - 성공 케이스

  @Test("정상_응답이면_디코딩된_객체를_반환한다")
  func 정상_응답이면_디코딩된_객체를_반환한다() async throws {
    let user = User(id: 1, name: "지성")
    let data = try JSONEncoder().encode(user)
    let session = MockSession.success(data: data)
    let client = makeClient(session: session)

    let result: User = try await client.request(MockRequest())
    #expect(result == user)
  }

  @Test("응답_바디가_필요_없는_요청이_성공한다")
  func 응답_바디가_필요_없는_요청이_성공한다() async throws {
    let session = MockSession.success()
    let client = makeClient(session: session)

    try await client.request(MockRequest())
  }

  @Test("DSL로_요청하면_정상적으로_디코딩된다")
  func DSL로_요청하면_정상적으로_디코딩된다() async throws {
    let user = User(id: 1, name: "지성")
    let data = try JSONEncoder().encode(user)
    let session = MockSession.success(data: data)
    let client = makeClient(session: session)

    let result: User = try await client.request {
      BaseURL("https://api.example.com")
      Path("users/1")
      Method(.get)
    }
    #expect(result == user)
  }

  // MARK: - Decode 에러

  @Test("응답_데이터가_비어있으면_noData_에러가_발생한다")
  func 응답_데이터가_비어있으면_noData_에러가_발생한다() async {
    let session = MockSession.success(data: Data())
    let client = makeClient(session: session)

    await #expect(throws: Network.Error.self) {
      let _: User = try await client.request(MockRequest())
    }
  }

  @Test("잘못된_JSON이면_invalidData_에러가_발생한다")
  func 잘못된_JSON이면_invalidData_에러가_발생한다() async {
    let session = MockSession.success(data: Data("invalid".utf8))
    let client = makeClient(session: session)

    await #expect(throws: Network.Error.self) {
      let _: User = try await client.request(MockRequest())
    }
  }

  // MARK: - Session 에러

  @Test("인터넷_연결이_없으면_notConnected_에러가_발생한다")
  func 인터넷_연결이_없으면_notConnected_에러가_발생한다() async {
    let session = MockSession.failure(URLError(.notConnectedToInternet))
    let client = makeClient(session: session, maxRetryCount: 0)

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  @Test("타임아웃이면_timeout_에러가_발생한다")
  func 타임아웃이면_timeout_에러가_발생한다() async {
    let session = MockSession.failure(URLError(.timedOut))
    let client = makeClient(session: session, maxRetryCount: 0)

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  @Test("요청이_취소되면_cancelled_에러가_발생한다")
  func 요청이_취소되면_cancelled_에러가_발생한다() async {
    let session = MockSession.failure(URLError(.cancelled))
    let client = makeClient(session: session, maxRetryCount: 0)

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  // MARK: - Response 에러

  @Test("401_응답이면_unauthorized_에러가_발생한다")
  func 상태코드_401이면_unauthorized_에러가_발생한다() async {
    let session = MockSession.success(statusCode: 401)
    let client = makeClient(session: session, maxRetryCount: 0)

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  @Test("500_응답이면_internalServerError_에러가_발생한다")
  func 상태코드_500이면_internalServerError_에러가_발생한다() async {
    let session = MockSession.success(statusCode: 500)
    let client = makeClient(session: session, maxRetryCount: 0)

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  // MARK: - Interceptor

  @Test("Interceptor의_adapt가_호출되어_요청이_변환된다")
  func Interceptor의_adapt가_호출되어_요청이_변환된다() async throws {
    let user = User(id: 1, name: "지성")
    let data = try JSONEncoder().encode(user)
    let session = MockSession.success(data: data)

    let interceptor = MockInterceptor()
    interceptor.adaptHandler = { request in
      var modified = request
      modified.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
      return modified
    }

    let client = makeClient(session: session, interceptors: [interceptor])
    let _: User = try await client.request(MockRequest())

    #expect(interceptor.adaptCallCount == 1)
    #expect(session.requestedURLRequests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
  }

  @Test("Interceptor의_adapt가_에러를_던지면_interceptor_adapt_에러가_발생한다")
  func Interceptor의_adapt가_에러를_던지면_adapt_에러가_발생한다() async {
    let session = MockSession.success()
    let interceptor = MockInterceptor()
    interceptor.adaptHandler = { _ in
      throw NSError(domain: "test", code: -1)
    }

    let client = makeClient(session: session, interceptors: [interceptor])

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  @Test("재시도_정책이_retry이면_요청을_다시_시도한다")
  func 재시도_정책이_retry이면_요청을_다시_시도한다() async throws {
    let user = User(id: 1, name: "지성")
    let data = try JSONEncoder().encode(user)
    let session = MockSession()

    // 첫 번째는 실패, 두 번째는 성공
    session.error = URLError(.timedOut)

    let interceptor = MockInterceptor()
    interceptor.retryHandler = { _, _, attemptCount in
      if attemptCount == 0 {
        // 재시도 전에 session을 성공으로 변경
        session.error = nil
        let response = HTTPURLResponse(
          url: URL(string: "https://api.example.com")!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        session.result = (data, response)
        return .retry(after: 0)
      }
      return .doNotRetry
    }

    let client = makeClient(session: session, interceptors: [interceptor])
    let result: User = try await client.request(MockRequest())

    #expect(result == user)
    #expect(interceptor.retryCallCount == 1)
  }

  @Test("최대_재시도_횟수를_초과하면_maxRetryExceeded_에러가_발생한다")
  func 최대_재시도_횟수를_초과하면_maxRetryExceeded_에러가_발생한다() async {
    let session = MockSession.failure(URLError(.timedOut))
    let interceptor = MockInterceptor()
    interceptor.retryHandler = { _, _, _ in .retry(after: 0) }

    let client = makeClient(session: session, interceptors: [interceptor], maxRetryCount: 2)

    await #expect(throws: Network.Error.self) {
      try await client.request(MockRequest())
    }
  }

  // MARK: - EventMonitor

  @Test("요청이_시작되면_EventMonitor의_requestDidStart가_호출된다")
  func 요청이_시작되면_requestDidStart가_호출된다() async throws {
    let user = User(id: 1, name: "지성")
    let data = try JSONEncoder().encode(user)
    let session = MockSession.success(data: data)
    let monitor = MockEventMonitor()
    let client = makeClient(session: session, eventMonitors: [monitor])

    let _: User = try await client.request(MockRequest())

    #expect(monitor.didStartRequests.count == 1)
  }

  @Test("요청이_성공하면_EventMonitor의_requestDidFinish가_호출된다")
  func 요청이_성공하면_requestDidFinish가_호출된다() async throws {
    let user = User(id: 1, name: "지성")
    let data = try JSONEncoder().encode(user)
    let session = MockSession.success(data: data)
    let monitor = MockEventMonitor()
    let client = makeClient(session: session, eventMonitors: [monitor])

    let _: User = try await client.request(MockRequest())

    #expect(monitor.didFinishResults.count == 1)
    #expect(monitor.didFinishResults.first?.1.statusCode == 200)
  }

  @Test("요청이_실패하면_EventMonitor의_requestDidFail이_호출된다")
  func 요청이_실패하면_requestDidFail이_호출된다() async {
    let session = MockSession.failure(URLError(.notConnectedToInternet))
    let monitor = MockEventMonitor()
    let client = makeClient(session: session, eventMonitors: [monitor], maxRetryCount: 0)

    _ = try? await client.request(MockRequest())

    #expect(monitor.didFailResults.count == 1)
  }
}
