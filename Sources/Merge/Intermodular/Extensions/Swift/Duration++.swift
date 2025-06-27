//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Swift.Duration {
    @_spi(Internal)
    public var _timeInterval: TimeInterval {
        TimeInterval(components.seconds) + Double(components.attoseconds) / 1e18
    }
    
    @_spi(Internal)
    public init(_timeInterval: TimeInterval) {
        let fraction = _timeInterval - floor(_timeInterval)
        
        self.init(
            secondsComponent: Int64(_timeInterval),
            attosecondsComponent: Int64(fraction * 1e18)
        )
    }
}
