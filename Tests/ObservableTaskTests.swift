//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class PassthroughTaskTests: XCTestCase {
    func testStatus() async throws {
        let task = PassthroughTask<Int, Error>(priority: nil) {
            try await Task.sleep(.seconds(1))
            
            return 69
        }
        
        XCTAssert(task.status == .inactive)
        
        task.start()
        
        XCTAssert(task.status == .active)
        
        let value = try await task.value
        
        XCTAssertEqual(value, 69)
    }
}
