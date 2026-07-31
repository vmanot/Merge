//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite("SystemShell direct execution")
struct SystemShellDirectExecutionTests {
    private struct Output: Decodable {
        let value: Int
    }

    @Test("Preserves executable paths and argv boundaries")
    func preservesExecutablePathsAndArgumentBoundaries() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let executableURL = directoryURL.appendingPathComponent("shell with spaces")

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: executableURL,
            withDestinationURL: URL(fileURLWithPath: "/bin/sh")
        )
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let result = try await SystemShell().run(
            executablePath: executableURL.path,
            arguments: [
                "-c",
                "printf '%s:%s' \"$#\" \"$1\"",
                "--",
                "hello world",
            ]
        )

        #expect(try result.toString() == "1:hello world")
    }

    @Test("Does not decode output from a failed process")
    func decodePreservesProcessFailure() async throws {
        let result = try await SystemShell().run(
            executablePath: "/bin/sh",
            arguments: ["-c", "printf '{\"value\":1}'; exit 7"]
        )

        #expect(!result.isSuccess)
        #expect(throws: Process.TerminationError.self) {
            try result.decode(Output.self)
        }
    }
}
