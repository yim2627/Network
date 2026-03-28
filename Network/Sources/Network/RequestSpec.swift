//
//  RequestSpec.swift
//  Network
//
//  Created by 임지성 on 3/28/26.
//

import Foundation

// MARK: - Component Protocol

public protocol RequestComponent {
  func apply(to spec: inout RequestSpec)
}

// MARK: - RequestSpec (Result Builder로 조립되는 Request 구현체)

public struct RequestSpec: Request {
  public var baseURL: String = ""
  public var path: String = ""
  public var method: HTTPMethod = .get
  public var headers: [String: String]?
  public var queryItems: [URLQueryItem]?
  public var body: (any Encodable)?
  public var timeoutInterval: TimeInterval?

  public init(@RequestSpecBuilder _ build: () -> [RequestComponent]) {
    let components = build()
    for component in components {
      component.apply(to: &self)
    }
  }
}

// MARK: - Result Builder

@resultBuilder
public struct RequestSpecBuilder {
  public static func buildExpression(_ expression: RequestComponent) -> [RequestComponent] {
    [expression]
  }

  public static func buildBlock(_ components: [RequestComponent]...) -> [RequestComponent] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [RequestComponent]?) -> [RequestComponent] {
    component ?? []
  }

  public static func buildEither(first component: [RequestComponent]) -> [RequestComponent] {
    component
  }

  public static func buildEither(second component: [RequestComponent]) -> [RequestComponent] {
    component
  }

  public static func buildArray(_ components: [[RequestComponent]]) -> [RequestComponent] {
    components.flatMap { $0 }
  }
}

// MARK: - DSL Components

public struct BaseURL: RequestComponent {
  private let value: String

  public init(_ value: String) {
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.baseURL = value
  }
}

public struct Path: RequestComponent {
  private let value: String

  public init(_ value: String) {
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.path = value
  }
}

public struct Method: RequestComponent {
  private let value: HTTPMethod

  public init(_ value: HTTPMethod) {
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.method = value
  }
}

public struct Header: RequestComponent {
  private let key: String
  private let value: String

  public init(_ key: String, _ value: String) {
    self.key = key
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.headers = spec.headers ?? [:]
    spec.headers?[key] = value
  }
}

public struct Query: RequestComponent {
  private let name: String
  private let value: String?

  public init(_ name: String, _ value: String?) {
    self.name = name
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.queryItems = spec.queryItems ?? []
    spec.queryItems?.append(URLQueryItem(name: name, value: value))
  }
}

public struct Body: RequestComponent {
  private let value: any Encodable

  public init(_ value: any Encodable) {
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.body = value
  }
}

public struct Timeout: RequestComponent {
  private let value: TimeInterval

  public init(_ value: TimeInterval) {
    self.value = value
  }

  public func apply(to spec: inout RequestSpec) {
    spec.timeoutInterval = value
  }
}
