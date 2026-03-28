//
//  NetworkClient.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

public protocol NetworkClientProtocol: Sendable {
  func request<T: Decodable>(_ request: Request) async throws(Network.Error) -> T
  func request(_ request: Request) async throws(Network.Error)
}

public final class NetworkClient: NetworkClientProtocol, Sendable {
  private let session: any Session
  private let configuration: NetworkConfiguration
  private let interceptors: [any Interceptor]
  private let eventMonitors: [any EventMonitor]
  private let requestBuilder: RequestBuilder
  private let responseValidator: ResponseValidator

  public init(
    configuration: NetworkConfiguration,
    session: any Session = URLSession.shared,
    interceptors: [any Interceptor] = [],
    eventMonitors: [any EventMonitor] = []
  ) {
    self.configuration = configuration
    self.session = session
    self.interceptors = interceptors
    self.eventMonitors = eventMonitors
    self.requestBuilder = RequestBuilder(configuration: configuration)
    self.responseValidator = ResponseValidator()
  }

  // MARK: - 응답 디코딩이 필요한 요청

  public func request<T: Decodable>(_ request: Request) async throws(Network.Error) -> T {
    let data = try await perform(request)

    guard !data.isEmpty else {
      throw .decode(.noData)
    }

    do {
      return try configuration.decoder.decode(T.self, from: data)
    } catch let error as DecodingError {
      throw .decode(.invalidData(error))
    } catch {
      throw .decode(.invalidData(nil))
    }
  }

  // MARK: - 응답 바디가 필요 없는 요청

  public func request(_ request: Request) async throws(Network.Error) {
    _ = try await perform(request)
  }

  // MARK: - Result Builder DSL

  public func request<T: Decodable>(
    @RequestSpecBuilder _ build: () -> [RequestComponent]
  ) async throws(Network.Error) -> T {
    let spec = RequestSpec(build)
    return try await request(spec)
  }

  public func request(
    @RequestSpecBuilder _ build: () -> [RequestComponent]
  ) async throws(Network.Error) {
    let spec = RequestSpec(build)
    try await request(spec)
  }
}

// MARK: - Private

extension NetworkClient {
  private func perform(_ request: Request) async throws(Network.Error) -> Data {
    var urlRequest = try requestBuilder.build(from: request)

    // Interceptor adapt
    for interceptor in interceptors {
      do {
        urlRequest = try await interceptor.adapt(urlRequest)
      } catch {
        throw .interceptor(.adapt(error))
      }
    }

    // EventMonitor - 요청 시작
    for monitor in eventMonitors {
      monitor.requestDidStart(urlRequest)
    }

    let startTime = CFAbsoluteTimeGetCurrent()

    do {
      let data = try await performWithRetry(urlRequest, attemptCount: 0)
      return data
    } catch {
      let duration = CFAbsoluteTimeGetCurrent() - startTime
      for monitor in eventMonitors {
        monitor.requestDidFail(urlRequest, error: error, duration: duration)
      }
      throw error
    }
  }

  private func performWithRetry(
    _ urlRequest: URLRequest,
    attemptCount: Int
  ) async throws(Network.Error) -> Data {
    do {
      let (data, response) = try await session.data(for: urlRequest)
      try responseValidator.validate(response, data: data)

      // EventMonitor - 요청 성공
      if let httpResponse = response as? HTTPURLResponse {
        for monitor in eventMonitors {
          monitor.requestDidFinish(
            urlRequest,
            response: httpResponse,
            data: data,
            duration: 0 // 개별 시도의 duration은 perform에서 총합 계산
          )
        }
      }

      return data
    } catch let error as Network.Error {
      return try await handleRetry(urlRequest, error: error, attemptCount: attemptCount)
    } catch let urlError as URLError {
      let networkError = mapURLError(urlError)
      return try await handleRetry(urlRequest, error: networkError, attemptCount: attemptCount)
    } catch {
      throw .unknown(error)
    }
  }

  private func handleRetry(
    _ urlRequest: URLRequest,
    error: Network.Error,
    attemptCount: Int
  ) async throws(Network.Error) -> Data {
    // 최대 재시도 횟수 초과
    guard attemptCount < configuration.maxRetryCount else {
      throw .interceptor(.maxRetryExceeded(attemptCount))
    }

    for interceptor in interceptors {
      let policy: RetryPolicy
      do {
        policy = try await interceptor.retry(urlRequest, error: error, attemptCount: attemptCount)
      } catch {
        throw .interceptor(.retry(error))
      }

      switch policy {
      case .retry(let delay):
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return try await performWithRetry(urlRequest, attemptCount: attemptCount + 1)
      case .doNotRetry:
        continue
      }
    }

    throw error
  }

  private func mapURLError(_ urlError: URLError) -> Network.Error {
    switch urlError.code {
    case .notConnectedToInternet, .networkConnectionLost:
      return .session(.notConnected)
    case .timedOut:
      return .session(.timeout)
    case .cancelled:
      return .session(.cancelled)
    case .dnsLookupFailed:
      return .session(.dnsLookupFailed)
    case .serverCertificateUntrusted, .secureConnectionFailed, .clientCertificateRejected:
      return .session(.sslFailed)
    default:
      return .session(.underlying(urlError))
    }
  }
}
