//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import XCTest

final class MergeTests: XCTestCase {
    func testOutput() {
        print(DispatchQoS.QoSClass.current)

        let f1 = Future.async(qos: .unspecified) {
            sleep(2)
        }
        
        let f2 = Future.async(qos: .unspecified) {
            sleep(2)
        }
        
        print(f1.subscribeAndWaitUntilDone(), f2.subscribeAndWaitUntilDone())
    }
}
