//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge

extension SystemShell {
    public func run(
        executablePath: String,
        arguments: [Process.ArgumentLiteral],
        environment: Environment = .zsh
    ) async throws -> Process.RunResult {
        try await run(
            executableURL: try URL(string: executablePath).unwrap(),
            arguments: arguments.map(\.rawValue),
            environment: environment
        )
    }
}

#endif
