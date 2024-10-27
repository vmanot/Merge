//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension CLT {
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
