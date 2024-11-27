//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// A type that wraps a command line tool.
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
