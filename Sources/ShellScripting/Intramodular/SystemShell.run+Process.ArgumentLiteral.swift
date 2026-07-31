//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge

extension SystemShell {
    public func run(
        executablePath: String,
        arguments: [Process.ArgumentLiteral]
    ) async throws -> Process.RunResult {
        try await run(
            executablePath: executablePath,
            arguments: arguments.map(\.rawValue)
        )
    }
}

#endif
