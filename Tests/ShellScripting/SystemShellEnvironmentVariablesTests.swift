//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite("SystemShell.EnvironmentVariables")
struct SystemShellEnvironmentVariablesTests {
    @Test("Inherited environment leaves Process.environment unset")
    func inheritedEnvironmentVariablesPreserveProcessInheritance() {
        #expect(
            SystemShell.EnvironmentVariables.inherited.resolvingForProcessLaunch() == nil,
            "A purely inherited environment should let Foundation.Process inherit from the parent process."
        )
    }

    @Test("Inherited environment variables can apply overrides")
    func inheritedEnvironmentVariablesCanApplyOverrides() throws {
        let variables = try #require(
            SystemShell.EnvironmentVariables
                .inherited(overriding: ["MERGE_TEST_ENV": "1"])
                .resolvingForProcessLaunch(),
            "An inherited environment with overrides should materialize launch variables."
        )

        #expect(variables["MERGE_TEST_ENV"] == "1", "Explicit overrides should be present in the launch environment.")
        #expect(
            variables["PATH"] == ProcessInfo.processInfo.environment["PATH"],
            "Inherited overrides should preserve parent process variables such as PATH."
        )
    }

    @Test("Subscript mutation preserves inherited environment compatibility")
    func inheritedEnvironmentVariablesPreserveSubscriptMutationCompatibility() throws {
        var environmentVariables = SystemShell.EnvironmentVariables.inherited

        environmentVariables["MERGE_TEST_ENV"] = "1"

        let variables = try #require(
            environmentVariables.resolvingForProcessLaunch(),
            "Legacy subscript mutation on an inherited environment should materialize launch variables."
        )

        #expect(variables["MERGE_TEST_ENV"] == "1", "Subscript mutation should add the requested override.")
        #expect(
            variables["PATH"] == ProcessInfo.processInfo.environment["PATH"],
            "Subscript mutation should not accidentally drop inherited variables."
        )
    }

    @Test("Exact environment variables do not inherit parent process variables")
    func exactEnvironmentVariablesDoNotInheritParentVariables() throws {
        let variables = try #require(
            SystemShell.EnvironmentVariables
                .exact(["MERGE_TEST_ENV": "1"])
                .resolvingForProcessLaunch(),
            "An exact environment should always materialize launch variables."
        )

        #expect(
            variables == ["MERGE_TEST_ENV": "1"],
            "Exact environments should contain only explicitly provided variables."
        )
    }

    @Test("Empty environment variables resolve to an empty dictionary")
    func emptyEnvironmentVariablesResolveToEmptyDictionary() throws {
        let variables = try #require(
            SystemShell.EnvironmentVariables.empty.resolvingForProcessLaunch(),
            "An empty environment should materialize an explicit empty launch dictionary."
        )

        #expect(variables.isEmpty, "The empty environment should launch with no variables.")
    }
}
