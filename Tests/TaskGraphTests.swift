//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class TaskGraphTests: XCTestCase {
    func testUseExistingPolicy() async throws {
        let graph = TaskGraph<TestTasks>()
        
        try await graph.insert(.foo) {
            try await Task.sleep(.milliseconds(200))
            
            return 1
        }
        
        let existingResult =  try await graph.insertAndWait(.foo, policy: .useExisting) {
            try await Task.sleep(.milliseconds(200))
            
            return 2
        }
        
        XCTAssertEqual(existingResult, 1)
        
        let freshResult = try await graph.insertAndWait(.foo, policy: .useExisting) {
            try await Task.sleep(.milliseconds(200))
            
            return 3
        }
        
        XCTAssertEqual(freshResult, 3)
    }
    
    func testUnspecifiedInsertionPolicyFailure() async throws {
        let graph = TaskGraph<TestTasks>()
        
        func insertLongFoo() async throws {
            try await graph.insert(.foo) {
                try await Task.sleep(.seconds(10))
            }
        }
        
        try await insertLongFoo()
        
        var caughtError: Error?
        
        do {
            try await insertLongFoo()
        } catch {
            caughtError = error
        }
        
        XCTAssertNotNil(caughtError)
    }
}

fileprivate enum TestTasks: Hashable, Sendable {
    case foo
    case bar
    case baz
}
