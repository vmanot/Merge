//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _CommandLineToolEnvironmentVariableProtocol: PropertyWrapper where WrappedValue: CLT.EnvironmentVariableValue {
    /// The name of the environment variable as it will be passed in the actual command being invoked.
    ///
    /// For e.g. `TARGET_BUILD_DIR` for `xcodebuild`.
    var name: String { get }
}

@propertyWrapper
public struct _CommandLineToolEnvironmentVariable<WrappedValue: CLT.EnvironmentVariableValue>: _CommandLineToolEnvironmentVariableProtocol {
    var _wrappedValue: WrappedValue
    
    public let name: String
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(wrappedValue: WrappedValue, name: String) {
        self._wrappedValue = wrappedValue
        self.name = name
    }
}

extension CommandLineTool {
    public typealias EnvironmentVariable<T: CLT.EnvironmentVariableValue> = _CommandLineToolEnvironmentVariable<T>
}
