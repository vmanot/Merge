//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class MergeTests: XCTestCase {
    func testSubscribeAndWait() {
        let f1 = Future.async(qos: .unspecified) { () -> Int in
            sleep(1)
            
            return 1
        }
        
        let f2 = Future.async(qos: .unspecified) { () -> Int in
            sleep(1)
            
            return 2
        }
        
        XCTAssert((f1.subscribeAndWaitUntilDone(), f2.subscribeAndWaitUntilDone()) == (1, 2))
    }
    
    func testEitherPublisher() {
        enum TestError: Hashable, Error {
            case some
        }
        
        var foo = true
        
        XCTAssert(
            Either {
                if foo {
                    Just("foo").setFailureType(to: TestError.self)
                } else {
                    Fail<String, TestError>(error: TestError.some)
                }
            }
            .subscribeAndWaitUntilDone() == .success("foo")
        )
        
        foo = false
        
        XCTAssert(
            Either {
                if foo {
                    Just("foo").setFailureType(to: TestError.self)
                } else {
                    Fail<String, TestError>(error: TestError.some)
                }
            }
            .subscribeAndWaitUntilDone() == .failure(TestError.some)
        )
    }
    
    func testWhilePublisher() {
        var count = 0
        
        Publishers.While(count < 100) {
            Just(()).then({ count += 1 })
        }
        .reduceAndMapTo(())
        .subscribeAndWaitUntilDone()
        
        XCTAssert(count == 100)
        
        enum TestError: Hashable, Error {
            case some
        }
        
        XCTAssert(
            Publishers.While(true) {
                Fail<Void, TestError>(error: TestError.some)
            }
            .reduceAndMapTo("foo")
            .subscribeAndWaitUntilDone() == .failure(TestError.some)
        )
    }
}
