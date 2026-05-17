//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite("SystemShell.Configuration", .serialized)
struct SystemShellConfigurationTests {
    @Test("Configuration differences round-trip complete configuration changes")
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
        let applied = try #require(
            source.applying(difference),
            "Applying a configuration difference should always produce a concrete configuration."
        )

        #expect(!difference.isEmpty, "A complete destination change should not produce an empty difference.")
        #expect(applied == destination, "Applying the difference should recreate the destination configuration exactly.")
    }

    @Test("Configuration differences merge distinct fields")
    func configurationDifferenceMergeAllowsDistinctFields() throws {
        var difference = SystemShell.Configuration.Difference.currentDirectoryURL(
            URL(fileURLWithPath: "/tmp/workspace")
        )

        try difference.mergeInPlace(with: .standardStreamMirroring(.disabled))

        let source = SystemShell.Configuration(standardStreamMirroring: .terminal)
        let applied = try #require(
            source.applying(difference),
            "Merged differences should still apply as a single configuration delta."
        )

        #expect(
            applied.currentDirectoryURL?.path == "/tmp/workspace",
            "The merged difference should replace the current directory."
        )
        #expect(
            applied.standardStreamMirroring == .disabled,
            "The merged difference should replace standard stream mirroring."
        )
    }

    @Test("Configuration differences allow idempotent duplicate fields")
    func configurationDifferenceMergeAllowsIdempotentDuplicates() throws {
        var difference = SystemShell.Configuration.Difference.standardStreamMirroring(.disabled)

        try difference.mergeInPlace(with: .standardStreamMirroring(.disabled))

        #expect(
            difference.standardStreamMirroring == .set(.disabled),
            "Merging the same field value twice should preserve a single replacement."
        )
    }

    @Test("Configuration differences reject conflicting duplicate fields")
    func configurationDifferenceMergeRejectsConflictingDuplicates() throws {
        var difference = SystemShell.Configuration.Difference.standardStreamMirroring(.disabled)

        do {
            try difference.mergeInPlace(with: .standardStreamMirroring(.terminal))

            Issue.record("Expected conflicting standard stream mirroring differences to throw.")
        } catch SystemShell.DeveloperError.conflictingConfigurationDifferences {
            #expect(
                difference.standardStreamMirroring == .set(.disabled),
                "A failed merge should leave the original difference intact."
            )
        } catch {
            Issue.record("Expected conflictingConfigurationDifferences, got \(error).")
        }
    }

    @Test("Scoped configuration does not mutate parent shell")
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
            #expect(
                child.configuration.standardStreamMirroring == .disabled,
                "The child shell should receive the scoped stream mirroring override."
            )
            #expect(
                child.configuration.currentDirectoryURL?.path == "/tmp",
                "The child shell should receive the scoped current-directory override."
            )
        }

        #expect(
            shell.configuration.standardStreamMirroring == .terminal,
            "Scoped configuration must not leak back into the parent shell."
        )
        #expect(
            shell.configuration.currentDirectoryURL == nil,
            "Scoped current-directory overrides must not mutate the parent shell."
        )
    }

    @Test("Scoped child shells share process tracking state")
    func scopedConfigurationSharesProcessTrackingState() async throws {
        let shell = SystemShell()

        try await shell.withConfiguration(
            applying: .standardStreamMirroring(.disabled)
        ) { child in
            let result = try await child.run(command: "echo scoped")

            #expect(result.stdoutString == "scoped", "The child shell should still capture stdout.")
        }

        let completedRunResults = await shell.completedRunResults

        #expect(
            completedRunResults.count == 1,
            "The parent shell should observe run results produced by scoped child shells."
        )
        #expect(
            completedRunResults.first?.stdoutString == "scoped",
            "The shared process history should preserve the child's captured stdout."
        )
    }

    @Test("Disabled mirroring still captures standard streams")
    func disabledMirroringStillCapturesStandardStreams() async throws {
        let shell = SystemShell(
            configuration: SystemShell.Configuration(
                standardStreamMirroring: .disabled
            )
        )

        let result = try await shell.run(command: "echo stdout-line")

        #expect(
            result.stdoutString == "stdout-line",
            ".disabled should suppress mirroring, not captured stdout."
        )
    }

    @Test("File mirroring preserves captured output")
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

        #expect(
            result.stdoutString == "stdout-line",
            "Mirroring to a file should not disable captured stdout."
        )
        #expect(
            mirrored.contains("stdout-line"),
            "The mirrored file should receive stdout content."
        )
    }
}
