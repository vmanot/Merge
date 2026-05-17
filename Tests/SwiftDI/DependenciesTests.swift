//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import SwiftDI
import Swallow
import Testing

@Suite
struct DependenciesTests {
    @Test
    func testBasics() async throws {
        let foo: Foo = withTaskDependencies {
            $0[unkeyed: Bar.self] = Baz1()
        } operation: {
            Foo()
        }

        #expect(foo.bongo() == 0)

        await Task.detached {
            #expect(foo.bongo() == 0)
        }
        .value

        withTaskDependencies {
            $0[unkeyed: Bar.self] = Baz2()
        } operation: {
            #expect(foo.baz is Baz2)
            #expect(foo.bongo() == 69)
        }

        try withTaskDependencies {
            $0[unkeyed: Bar.self] = nil
        } operation: {
            try foo.tryBongo()
        }

        await withTaskDependencies {
            $0[unkeyed: Bar.self] = Baz1()
        } operation: {
            let result = await Result(catching: {
                try await tryDetachedFoo()
            })

            do {
                _ = try result.get()
                Issue.record("Expected detached dependency lookup to throw.")
            } catch {

            }
        }
    }

    @Test
    func testAsyncAndRecursive() async throws {
        let foo: Foo = withTaskDependencies {
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

        try result.get()
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
        @TaskDependency() var baz: Bar

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
            try withTaskDependencies(from: self) {
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
