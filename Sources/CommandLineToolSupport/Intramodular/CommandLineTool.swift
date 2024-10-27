//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// A type that wraps a command line tool.
public protocol CommandLineTool: AnyCommandLineTool {
    associatedtype EnvironmentVariables = _CommandLineTool_DefaultEnvironmentVariables
    
    typealias Parameter<T> = _CommandLineToolParameter<T>
}

public enum CommandLineTools {
    
}

// MARK: - Supplementary

public typealias CLT = CommandLineTools

// MARK: - Auxiliary

public struct _CommandLineTool_DefaultEnvironmentVariables {
    
}
