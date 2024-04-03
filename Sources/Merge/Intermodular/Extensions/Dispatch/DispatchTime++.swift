//
// Copyright (c) Vatsal Manot
//

import Dispatch

extension DispatchTime {
    public var uptimeMilliseconds: UInt64 {
        uptimeNanoseconds / 1_000_000
    }
}
