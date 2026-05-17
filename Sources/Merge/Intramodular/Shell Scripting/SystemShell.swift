//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Swallow

public final class SystemShell: Logging {
    package enum Ownership {
        case local
        case borrowedFromCommandLineTool
    }

    public var environmentVariables: EnvironmentVariables
    public var currentDirectoryURL: URL?
    public var options: [_AsyncProcessOption]?

    package let _internalState = _InternalState()
    package var ownership: Ownership = .local

    public init(
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcessOption]? = nil
    ) {
        self.environmentVariables = .inherited(overriding: environment ?? [:])
        self.currentDirectoryURL = currentDirectoryURL
        self.options = options
    }

    public init(
        environmentVariables: EnvironmentVariables,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcessOption]? = nil
    ) {
        self.environmentVariables = environmentVariables
        self.currentDirectoryURL = currentDirectoryURL
        self.options = options
    }
}
