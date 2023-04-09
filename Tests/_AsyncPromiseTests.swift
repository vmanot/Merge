//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class _AsyncPromiseTests: XCTestCase {
    func test() async throws {
        for _ in 0..<1000 {
            let promise = _AsyncPromise<Int, Never>()
            
            Task.detached(priority: .userInitiated) {
                promise.fulfill(with: .success(1))
            }
            
            let result = await promise.get()
            
            XCTAssert(result == 1)
        }
    }
}
