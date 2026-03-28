//
//  RequestSpecTests.swift
//  NetworkTests
//
//  Created by 임지성 on 3/28/26.
//

import Testing
import Foundation
@testable import Network

@Suite("RequestSpec DSL 테스트")
struct RequestSpecTests {

  @Test("BaseURL을_설정하면_baseURL이_반영된다")
  func BaseURL을_설정하면_baseURL이_반영된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
    }
    #expect(spec.baseURL == "https://api.example.com")
  }

  @Test("Path를_설정하면_path가_반영된다")
  func Path를_설정하면_path가_반영된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users/1")
    }
    #expect(spec.path == "users/1")
  }

  @Test("Method를_설정하면_method가_반영된다")
  func Method를_설정하면_method가_반영된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      Method(.post)
    }
    #expect(spec.method == .post)
  }

  @Test("Method를_설정하지_않으면_기본값은_GET이다")
  func Method를_설정하지_않으면_기본값은_GET이다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
    }
    #expect(spec.method == .get)
  }

  @Test("Header를_설정하면_headers에_추가된다")
  func Header를_설정하면_headers에_추가된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      Header("Authorization", "Bearer token")
      Header("Accept", "application/json")
    }
    #expect(spec.headers?["Authorization"] == "Bearer token")
    #expect(spec.headers?["Accept"] == "application/json")
  }

  @Test("Query를_설정하면_queryItems에_추가된다")
  func Query를_설정하면_queryItems에_추가된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      Query("page", "1")
      Query("limit", "20")
    }
    #expect(spec.queryItems?.count == 2)
    #expect(spec.queryItems?.first?.name == "page")
    #expect(spec.queryItems?.first?.value == "1")
  }

  @Test("Body를_설정하면_body가_반영된다")
  func Body를_설정하면_body가_반영된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      Method(.post)
      Body(["name": "test"])
    }
    #expect(spec.body != nil)
  }

  @Test("Timeout을_설정하면_timeoutInterval이_반영된다")
  func Timeout을_설정하면_timeoutInterval이_반영된다() {
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      Timeout(60)
    }
    #expect(spec.timeoutInterval == 60)
  }

  @Test("if_조건이_true이면_컴포넌트가_적용된다")
  func if_조건이_true이면_컴포넌트가_적용된다() {
    let needsAuth = true
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      if needsAuth {
        Header("Authorization", "Bearer token")
      }
    }
    #expect(spec.headers?["Authorization"] == "Bearer token")
  }

  @Test("if_조건이_false이면_컴포넌트가_적용되지_않는다")
  func if_조건이_false이면_컴포넌트가_적용되지_않는다() {
    let needsAuth = false
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("users")
      if needsAuth {
        Header("Authorization", "Bearer token")
      }
    }
    #expect(spec.headers == nil)
  }

  @Test("if_else_분기가_올바르게_동작한다")
  func if_else_분기가_올바르게_동작한다() {
    let isAdmin = true
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      if isAdmin {
        Path("admin/users")
      } else {
        Path("users")
      }
    }
    #expect(spec.path == "admin/users")
  }

  @Test("for_반복문이_올바르게_동작한다")
  func for_반복문이_올바르게_동작한다() {
    let tags = ["swift", "ios", "network"]
    let spec = RequestSpec {
      BaseURL("https://api.example.com")
      Path("search")
      for tag in tags {
        Query("tag", tag)
      }
    }
    #expect(spec.queryItems?.count == 3)
    #expect(spec.queryItems?[0].value == "swift")
    #expect(spec.queryItems?[2].value == "network")
  }
}
