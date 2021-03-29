//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import XCTest

final class MergeTests: XCTestCase {
    func subscribeAndWaitUntilDoneTests() {
        print(DispatchQoS.QoSClass.current)

        let f1 = Future.async(qos: .unspecified) { () -> Int in
            sleep(2)
            
            return 1
        }
        
        let f2 = Future.async(qos: .unspecified) { () -> Int in
            sleep(2)
            
            return 2
        }
        
        XCTAssert((f1.subscribeAndWaitUntilDone(), f2.subscribeAndWaitUntilDone()) == (1, 2))
    }
}
