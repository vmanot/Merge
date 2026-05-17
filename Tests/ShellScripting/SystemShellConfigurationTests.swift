//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite(.serialized)
struct SystemShellConfigurationTests {
    @Test
    func configurationDifferenceRoundTripsCompleteConfigurations() throws {
        let source = SystemShell.Configuration(
            environmentVariables: .inherited,
            currentDirectoryURL: URL(fileURLWithPath: "/tmp/source"),
            standardStreamMirroring: .disabled
        )
        let destination = SystemShell.Configuration(
            environmentVariables: .exact(["MERGE_TEST": "1"]),
            currentDirectoryURL: nil,
            standardStreamMirroring: .terminal
        )

        let difference = destination.difference(from: source)
        let applied = try #require(source.applying(difference))

        #expect(!difference.isEmpty)
        #expect(applied == destination)
    }

    @Test
    func configurationDifferenceMergeAllowsDistinctFields() throws {
        var difference = SystemShell.Configuration.Difference.currentDirectoryURL(
            URL(fileURLWithPath: "/tmp/workspace")
        )

        try difference.mergeInPlace(with: .standardStreamMirroring(.disabled))

        let source = SystemShell.Configuration(standardStreamMirroring: .terminal)
        let applied = try #require(source.applying(difference))

        #expect(applied.currentDirectoryURL?.path == "/tmp/workspace")
        #expect(applied.standardStreamMirroring == .disabled)
    }

    @Test
    func configurationDifferenceMergeAllowsIdempotentDuplicates() throws {
        var difference = SystemShell.Configuration.Difference.standardStreamMirroring(.disabled)

        try difference.mergeInPlace(with: .standardStreamMirroring(.disabled))

        #expect(difference.standardStreamMirroring == .set(.disabled))
    }

    @Test
    func configurationDifferenceMergeRejectsConflictingDuplicates() throws {
        var difference = SystemShell.Configuration.Difference.standardStreamMirroring(.disabled)

        do {
            try difference.mergeInPlace(with: .standardStreamMirroring(.terminal))

            Issue.record("Expected conflicting configuration differences to throw.")
        } catch {
            #expect(String(describing: error).contains("conflicting SystemShell.Configuration.Difference"))
        }
    }

    @Test
    func scopedConfigurationDoesNotMutateParentShell() async throws {
        let shell = SystemShell(
            configuration: SystemShell.Configuration(
                currentDirectoryURL: nil,
                standardStreamMirroring: .terminal
            )
        )

        try await shell.withConfiguration(
            applying: .standardStreamMirroring(.disabled),
            .currentDirectoryURL(URL(fileURLWithPath: "/tmp"))
        ) { child in
            #expect(child.configuration.standardStreamMirroring == .disabled)
            #expect(child.configuration.currentDirectoryURL?.path == "/tmp")
        }

        #expect(shell.configuration.standardStreamMirroring == .terminal)
        #expect(shell.configuration.currentDirectoryURL == nil)
    }

    @Test
    func scopedConfigurationSharesProcessTrackingState() async throws {
        let shell = SystemShell()

        try await shell.withConfiguration(
            applying: .standardStreamMirroring(.disabled)
        ) { child in
            let result = try await child.run(command: "echo scoped")

            #expect(result.stdoutString == "scoped")
        }

        #expect(await shell.completedRunResults.count == 1)
        #expect(await shell.completedRunResults.first?.stdoutString == "scoped")
    }

    @Test
    func disabledMirroringStillCapturesStandardStreams() async throws {
        let shell = SystemShell(
            configuration: SystemShell.Configuration(
                standardStreamMirroring: .disabled
            )
        )

        let result = try await shell.run(command: "echo stdout-line")

        #expect(result.stdoutString == "stdout-line")
    }

    @Test
    func fileMirroringPreservesCapturedOutput() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let logFile = directory.appendingPathComponent("combined.log")

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let shell = SystemShell(
            configuration: SystemShell.Configuration(
                standardStreamMirroring: .file(logFile)
            )
        )

        let result = try await shell.run(command: "echo stdout-line")
        let mirrored = try String(contentsOf: logFile, encoding: .utf8)

        #expect(result.stdoutString == "stdout-line")
        #expect(mirrored.contains("stdout-line"))
    }
}
