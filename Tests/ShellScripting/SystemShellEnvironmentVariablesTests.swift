//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite
struct SystemShellEnvironmentVariablesTests {
    @Test
    func inheritedEnvironmentVariablesPreserveProcessInheritance() {
        #expect(SystemShell.EnvironmentVariables.inherited.resolvingForProcessLaunch() == nil)
    }

    @Test
    func inheritedEnvironmentVariablesCanApplyOverrides() throws {
        let variables = try #require(
            SystemShell.EnvironmentVariables
                .inherited(overriding: ["MERGE_TEST_ENV": "1"])
                .resolvingForProcessLaunch()
        )

        #expect(variables["MERGE_TEST_ENV"] == "1")
        #expect(variables["PATH"] == ProcessInfo.processInfo.environment["PATH"])
    }

    @Test
    func inheritedEnvironmentVariablesPreserveSubscriptMutationCompatibility() throws {
        var environmentVariables = SystemShell.EnvironmentVariables.inherited

        environmentVariables["MERGE_TEST_ENV"] = "1"

        let variables = try #require(environmentVariables.resolvingForProcessLaunch())

        #expect(variables["MERGE_TEST_ENV"] == "1")
        #expect(variables["PATH"] == ProcessInfo.processInfo.environment["PATH"])
    }

    @Test
    func exactEnvironmentVariablesDoNotInheritParentVariables() throws {
        let variables = try #require(
            SystemShell.EnvironmentVariables
                .exact(["MERGE_TEST_ENV": "1"])
                .resolvingForProcessLaunch()
        )

        #expect(variables == ["MERGE_TEST_ENV": "1"])
    }

    @Test
    func emptyEnvironmentVariablesResolveToEmptyDictionary() throws {
        let variables = try #require(
            SystemShell.EnvironmentVariables.empty.resolvingForProcessLaunch()
        )

        #expect(variables.isEmpty)
    }
}
