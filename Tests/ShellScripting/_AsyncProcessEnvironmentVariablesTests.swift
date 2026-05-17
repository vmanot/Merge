//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite
struct _AsyncProcessEnvironmentVariablesTests {
    @Test
    func inheritedEnvironmentVariablesLeaveFoundationProcessEnvironmentUnset() throws {
        let process = try _AsyncProcess(
            launchPath: "/usr/bin/env",
            arguments: [],
            environmentVariables: _AsyncProcess.EnvironmentVariables.inherited,
            options: []
        )

        #expect(process.environmentVariables == .inherited)
        #expect(process.process.environment == nil)
    }

    @Test
    func exactEnvironmentVariablesAreAppliedWhenProcessRuns() async throws {
        let process = try _AsyncProcess(
            launchPath: "/usr/bin/env",
            arguments: [],
            environmentVariables: _AsyncProcess.EnvironmentVariables.exact(["MERGE_TEST_ENV": "1"]),
            options: []
        )

        let result = try await process.run()

        #expect(result.stdoutString == "MERGE_TEST_ENV=1")
    }

    @Test
    func settingEnvironmentVariablesBeforeLaunchAppliesWhenProcessRuns() async throws {
        let process = try _AsyncProcess(
            launchPath: "/usr/bin/env",
            arguments: [],
            environmentVariables: _AsyncProcess.EnvironmentVariables.inherited,
            options: []
        )

        process.environmentVariables = .empty

        let result = try await process.run()

        #expect(result.stdoutString == nil)
    }

    @Test
    func inheritedOverridesResolveAtProcessLayer() throws {
        let variables = try #require(
            _AsyncProcess.EnvironmentVariables
                .inherited(overriding: ["MERGE_TEST_ENV": "1"])
                .resolvingForProcessLaunch()
        )

        #expect(variables["MERGE_TEST_ENV"] == "1")
        #expect(variables["PATH"] == ProcessInfo.processInfo.environment["PATH"])
    }
}
