//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension CLT {
    /// A type that can represent the raw value of an environment variable to be passed in a command invocation.
    public protocol EnvironmentVariableValue {
        
    }
}

extension Optional: CLT.EnvironmentVariableValue where Wrapped: CLT.EnvironmentVariableValue {
    
}

extension Bool: CLT.EnvironmentVariableValue {
    
}

extension Int: CLT.EnvironmentVariableValue {
    
}

extension String: CLT.EnvironmentVariableValue {
    
}

extension URL: CLT.EnvironmentVariableValue {
    
}
