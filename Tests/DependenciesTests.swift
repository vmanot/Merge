//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class DependenciesTests: XCTestCase {
    func testBasics() async throws {
        let foo: Foo = withDependencies {
            $0[unkeyed: Bar.self] = Baz1()
        } operation: {
            Foo()
        }
        
        XCTAssertEqual(foo.bongo(), 0)
        
        await Task.detached {
            XCTAssertEqual(foo.bongo(), 0)
        }
        .value
        
        withDependencies {
            $0[unkeyed: Bar.self] = Baz2()
        } operation: {
            XCTAssert(foo.baz is Baz2)
            XCTAssertEqual(foo.bongo(), 69)
        }
        
        XCTAssertNoThrow(
            try withDependencies {
                $0[unkeyed: Bar.self] = nil
            } operation: {
                try foo.tryBongo()
            }
        )
        
        try await withDependencies {
            $0[unkeyed: Bar.self] = Baz1()
        } operation: {
            let result = await Result(catching: {
                try await tryDetachedFoo()
            })
            
            XCTAssertThrowsError(try result.get())
        }
    }
    
    func testAsyncAndRecursive() async throws {
        let foo: Foo = withDependencies {
            $0[unkeyed: Bar.self] = Baz1()
        } operation: {
            Foo()
        }
        
        let result = await Result(catching: {
            try foo.tryBongo()
            try foo.tryRecursiveBongo()
            
            _ = try await Task.detached {
                try foo.tryRecursiveBongo()
            }
            .value
        })
        
        XCTAssertNoThrow(try result.get())
    }
    
    func tryFoo() async throws {
        _ = try await Task {
            try Foo().tryBongo()
        }
        .value
        
        try Foo().tryRecursiveBongo()
    }
    
    func tryDetachedFoo() async throws {
        _ = try await Task.detached {
             try Foo().tryBongo()
        }
        .value
    }
}

extension DependenciesTests {
    typealias Bar = _DependenciesTests_Bar
    
    struct Foo {
        @Dependency var baz: Bar
        
        @discardableResult
        func bongo() -> Int {
            baz.baz()
        }
        
        @discardableResult
        func tryBongo() throws -> Int {
            try $baz.get().baz()
        }
        
        @discardableResult
        func tryRecursiveBongo() throws -> Int {
            try withDependencies(from: self) {
                try Foo().tryBongo()
            }
        }
    }
    
    struct Baz1: _DependenciesTests_Bar {
        func baz() -> Int {
            0
        }
    }
    
    struct Baz2: _DependenciesTests_Bar {
        func baz() -> Int {
            69
        }
    }
}

protocol _DependenciesTests_Bar {
    func baz() -> Int
}
