//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public func withUnsafeSystemShell<R>(
        sink: _ProcessStandardOutputSink,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withUnsafeSystemShell { shell in
            try await shell.withConfiguration(
                applying: .standardStreamMirroring(
                    SystemShell.StandardStreamMirroring(processStandardOutputSink: sink)
                ),
                perform: operation
            )
        }
    }
}

#endif
