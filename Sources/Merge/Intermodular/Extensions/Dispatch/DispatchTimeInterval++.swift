//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Foundation
import Swallow

extension DispatchTimeInterval {
    /// Converts the value to a `TimeInterval`.
    ///
    /// Throws if the conversion fails (for e.g. if attempting to convert `.never`).
    public func toTimeInterval() throws -> TimeInterval {
        enum ConversionError: Error {
            case failedToConvertNever
            case unknownCase
        }
        
        var result: Double
        
        switch self {
            case .seconds(let value):
                result = Double(value)
            case .milliseconds(let value):
                result = Double(value)*0.001
            case .microseconds(let value):
                result = Double(value)*0.000001
            case .nanoseconds(let value):
                result = Double(value)*0.000000001
            case .never:
                throw ConversionError.failedToConvertNever
            @unknown default:
                throw ConversionError.unknownCase
        }
        
        return result
    }
}
