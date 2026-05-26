#if os(macOS)

import CommandLineToolSupport
import Foundation
import Testing

private func hasInvocationSummaryParentConformance(
    _ type: Any.Type
) -> Bool {
    type is any _InvocationSummarySubcommandWithParentCommand.Type
}

private func hasCommandLineToolConformance(
    _ type: Any.Type
) -> Bool {
    type is any CommandLineTool.Type
}

@Suite
struct CommandLineToolSupportExampleTests {
    @Test
    func modelsASwiftBuildInvocationWithoutInvocationSummary() throws {
        let command = ExampleSwiftTool()
            .with(\.verbose, true)
            .with(\.sdk, "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk")
            .build()
            .with(\.configuration, .release)
            .with(\.verbosity, 2)
            .with(\.sandbox, false)
            .with(\.packagePath, "Fixtures/Example Package")
            .with(\.triple, "arm64-apple-macosx15.0")
            .with(\.swiftcOptions, [
                .define("TRACE_IMPORTS"),
                .unsafeFlag("-emit-loaded-module-trace")
            ])
            .with(\.explicitProducts, [
                "ExampleCLI",
                "ExampleSupport"
            ])

        let invocation = try command.commandInvocation

        #expect(invocation.commandName == "swift")
        #expect(invocation.arguments.map(\.rawValue) == [
            "--verbose",
            "-sdk",
            "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk",
            "build",
            "--release",
            "-vv",
            "--no-sandbox",
            "--package-path",
            "Fixtures/Example Package",
            "--triple=arm64-apple-macosx15.0",
            "-Xswiftc",
            "-DTRACE_IMPORTS",
            "-Xswiftc",
            "-emit-loaded-module-trace",
            "ExampleCLI",
            "ExampleSupport"
        ])
        #expect(
            invocation.commandLine == "swift --verbose -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk build --release -vv --no-sandbox --package-path Fixtures/Example Package --triple=arm64-apple-macosx15.0 -Xswiftc -DTRACE_IMPORTS -Xswiftc -emit-loaded-module-trace ExampleCLI ExampleSupport"
        )
    }

    @Test
    func modelsNestedGitSubcommands() throws {
        let pushInvocation = try ExampleGitTool()
            .with(\.localRepositoryURL, URL(fileURLWithPath: "/tmp/repo"))
            .with(\.tags, true)
            .with(\.force, true)
            .push()
            .invocation

        let remoteUpdateInvocation = try ExampleGitTool()
            .with(\.verbose, true)
            .with(\.prune, true)
            .remote()
            .update()
            .invocation

        #expect(pushInvocation == "git -C /tmp/repo push --tags --force")
        #expect(remoteUpdateInvocation == "git remote --verbose update --prune")
    }

    @Test
    func subcommandMacroCanMarkPlainNestedSubcommandsWithoutInvocationSummaryCoupling() throws {
        let command = try ExamplePlainSubcommandTool()
            .leaf()
            .with(\.verbose, true)
            .invocation
        let extensionCommand = try ExamplePlainSubcommandTool()
            .extensionLeaf()
            .with(\.dryRun, true)
            .invocation

        #expect(command == "plain leaf --verbose")
        #expect(extensionCommand == "plain extension-leaf --dry-run")
        #expect(hasCommandLineToolConformance(ExamplePlainSubcommandTool.Leaf.self))
        #expect(hasCommandLineToolConformance(ExamplePlainSubcommandTool.ExtensionLeaf.self))
        #expect(!hasInvocationSummaryParentConformance(ExamplePlainSubcommandTool.Leaf.self))
        #expect(!hasInvocationSummaryParentConformance(ExamplePlainSubcommandTool.ExtensionLeaf.self))
    }

    @Test
    func modelsSandboxExecWrappingModeledSwiftInvocation() throws {
        let swiftBuild = ExampleSwiftTool()
            .build()
            .with(\.configuration, .release)
            .with(\.packagePath, "Fixtures/Example Package")
            .with(\.explicitProducts, ["ExampleCLI"])

        let command = try ExampleSandboxExecTool()
            .with(\.profileFilePath, "Profiles/no-network.sb")
            .executing(swiftBuild)

        let invocation = try command.commandInvocation
        let description = try command.resolve()
        let profileFilePath = try #require(
            description.arguments[id: .init(rawValue: "profileFilePath", commandName: "sandbox-exec")]
        )
        let commandAndArguments = try #require(
            description.arguments[id: .init(rawValue: "commandAndArguments", commandName: "sandbox-exec")]
        )

        #expect(invocation.commandLine == "sandbox-exec -f Profiles/no-network.sb swift build --release --package-path Fixtures/Example Package ExampleCLI")
        #expect(profileFilePath.publicInvocationComponents.map(\.kind) == [.option])
        #expect(profileFilePath.publicInvocationComponents.first?.key?.rawValue == "-f")
        #expect(profileFilePath.publicInvocationComponents.first?.values.rawValues == ["Profiles/no-network.sb"])
        #expect(commandAndArguments.publicInvocationComponents.map(\.kind) == Array(repeating: .positionalArgument, count: 6))
    }

    @Test
    func invocationSummaryCanModelDoccStaticHostingWorkflow() throws {
        let command = try ExampleDocumentationCompilerTool()
            .with(\.catalogPath, "Documentation.docc")
            .with(\.outputPath, ".build/site")
            .with(\.transformForStaticHosting, true)
            .with(\.hostingBasePath, "/project")
            .with(\.emitDigest, true)
            .invocation

        #expect(
            command == "docc convert Documentation.docc --output-path .build/site --transform-for-static-hosting --hosting-base-path /project --emit-digest"
        )
    }

    @Test
    func invocationSummaryCanModelDoccPreviewWorkflow() throws {
        let command = try ExampleDocumentationCompilerTool()
            .with(\.operation, .preview)
            .with(\.catalogPath, "Documentation.docc")
            .with(\.port, 8080)
            .invocation

        #expect(command == "docc preview Documentation.docc --port 8080")
    }

    @Test
    func invocationSummaryCanForwardParentConfigurationIntoSubcommand() throws {
        #expect(hasInvocationSummaryParentConformance(ExampleXcodebuildLikeTool.Test.self))

        let command = try ExampleXcodebuildLikeTool()
            .with(\.scheme, "ExampleApp")
            .with(\.destination, "platform=iOS Simulator,name=iPhone 15")
            .with(\.enableCodeCoverage, .enabled)
            .test()
            .with(\.testPlan, "Smoke")
            .with(\.onlyTesting, ["ExampleAppTests/LoginTests"])
            .with(\.skipTesting, ["ExampleAppTests/SlowTests"])
            .invocation

        #expect(
            command == "xcodebuild test -scheme ExampleApp -destination platform=iOS Simulator,name=iPhone 15 -enableCodeCoverage YES -testPlan Smoke -only-testing ExampleAppTests/LoginTests -skip-testing ExampleAppTests/SlowTests"
        )
    }

    @Test
    func invocationSummaryCanRewriteXcodebuildResultBundlePathAsStructuredOptionComponent() throws {
        let command = ExampleXcodebuildLikeTool()
            .with(\.workspace, "ExampleApp.xcworkspace")
            .with(\.scheme, "ExampleApp")
            .with(\.destination, "platform=iOS Simulator,name=iPhone 15")
            .test()
            .with(\.resultBundlePath, ".build/TestResults")
            .with(\.parallelTestingEnabled, false)
        let invocation = try command.commandInvocation
        let resultBundleComponent = try #require(
            invocation.components.first {
                $0.key?.rawValue == "-resultBundlePath"
            }
        )

        #expect(
            invocation.commandLine == "xcodebuild test -workspace ExampleApp.xcworkspace -scheme ExampleApp -destination platform=iOS Simulator,name=iPhone 15 -resultBundlePath .build/TestResults.xcresult -no-parallel-testing-enabled"
        )
        #expect(resultBundleComponent.kind == .option)
        #expect(resultBundleComponent.key?.rawValue == "-resultBundlePath")
        #expect(resultBundleComponent.values.rawValues == [".build/TestResults.xcresult"])
    }

    @Test
    func invocationSummaryRejectsUnsupportedParentArgumentsWithStructuredDiagnostics() throws {
        do {
            _ = try ExampleXcodebuildLikeTool()
                .with(\.scheme, "ExampleApp")
                .with(\.enableCodeCoverage, .enabled)
                .analyze()
                .invocation

            Issue.record("Expected analyze to reject test-only code coverage configuration.")
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .unsupportedArgument(let command, let argument, let disposition, let components, let reason, let location) = error else {
                Issue.record("Expected unsupportedArgument, got \(error).")
                return
            }

            #expect(command == "xcodebuild")
            #expect(argument.rawValue == "enableCodeCoverage")
            #expect(disposition == .unavailable)
            #expect(components.flatMap(\.rawValues) == ["-enableCodeCoverage", "YES"])
            #expect(reason == "-enableCodeCoverage is only meaningful for test actions")
            #expect(location != nil)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).")
        }
    }

    @Test
    func invocationSummaryApplicabilityExamplesContrastNodeAndModifierOmission() throws {
        let nodeStyle = try ExampleNodeApplicabilityTool()
            .with(\.workspace, "Example.xcworkspace")
            .with(\.enableCoverage, .enabled)
            .build()
            .invocation
        let modifierStyle = try ExampleModifierApplicabilityTool()
            .with(\.workspace, "Example.xcworkspace")
            .with(\.enableCoverage, .enabled)
            .build()
            .invocation

        #expect(nodeStyle == "applicability-example build -workspace Example.xcworkspace")
        #expect(modifierStyle == nodeStyle)
    }

    @Test
    func invocationSummaryApplicabilityExamplesContrastNodeAndModifierDiagnostics() throws {
        try expectApplicabilityExampleUnsupportedCoverageError(
            from: {
                _ = try ExampleNodeApplicabilityTool()
                    .with(\.workspace, "Example.xcworkspace")
                    .with(\.enableCoverage, .enabled)
                    .analyze()
                    .invocation
            },
            commandName: "applicability-example",
            reason: "-enableCoverage is only valid for test"
        )
        try expectApplicabilityExampleUnsupportedCoverageError(
            from: {
                _ = try ExampleModifierApplicabilityTool()
                    .with(\.workspace, "Example.xcworkspace")
                    .with(\.enableCoverage, .enabled)
                    .analyze()
                    .invocation
            },
            commandName: "applicability-example",
            reason: "-enableCoverage is only valid for test"
        )
    }

    @Test
    func invocationSummaryApplicabilityExamplesPreserveValidRendering() throws {
        let nodeStyle = try ExampleNodeApplicabilityTool()
            .with(\.workspace, "Example.xcworkspace")
            .with(\.enableCoverage, .enabled)
            .test()
            .invocation
        let modifierStyle = try ExampleModifierApplicabilityTool()
            .with(\.workspace, "Example.xcworkspace")
            .with(\.enableCoverage, .enabled)
            .test()
            .invocation

        #expect(nodeStyle == "applicability-example test -workspace Example.xcworkspace -enableCoverage YES")
        #expect(modifierStyle == nodeStyle)
    }

    private func expectApplicabilityExampleUnsupportedCoverageError(
        from operation: () throws -> Void,
        commandName: CommandLineTool.Name,
        reason expectedReason: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        do {
            try operation()

            Issue.record("Expected applicability example to reject coverage.", sourceLocation: sourceLocation)
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .unsupportedArgument(let command, let argument, let disposition, let components, let reason, let location) = error else {
                Issue.record("Expected unsupportedArgument, got \(error).", sourceLocation: sourceLocation)
                return
            }

            #expect(command == commandName, sourceLocation: sourceLocation)
            #expect(argument.rawValue == "enableCoverage", sourceLocation: sourceLocation)
            #expect(argument.commandName == commandName, sourceLocation: sourceLocation)
            #expect(disposition == .unavailable, sourceLocation: sourceLocation)
            #expect(components.flatMap(\.rawValues) == ["-enableCoverage", "YES"], sourceLocation: sourceLocation)
            #expect(reason == expectedReason, sourceLocation: sourceLocation)
            #expect(location != nil, sourceLocation: sourceLocation)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).", sourceLocation: sourceLocation)
        }
    }

    @Test
    func invocationSummaryCanOmitParentCoverageFromXcodebuildBuild() throws {
        #expect(hasInvocationSummaryParentConformance(ExampleXcodebuildLikeTool.Build.self))

        let xcodebuild = ExampleXcodebuildLikeTool()
            .with(\.scheme, "ExampleApp")
            .with(\.destination, "platform=iOS Simulator,name=iPhone 15")
            .with(\.enableCodeCoverage, .enabled)

        try xcodebuild._attachOutputFormatterTool(
            ExampleXcbeautifyTool().with(\.disableColoredOutput, true)
        )

        let command = try xcodebuild
            .build()
            .invocation
        let formatter = try #require(xcodebuild._attachedOutputFormatterTool)
            .invocation

        #expect(formatter == "xcbeautify --disable-colored-output")
        #expect(
            command == "xcodebuild build -scheme ExampleApp -destination platform=iOS Simulator,name=iPhone 15"
        )
    }

    @Test
    func invocationSummaryCanModelXcodebuildArchiveWithParentConfiguration() throws {
        #expect(hasInvocationSummaryParentConformance(ExampleXcodebuildLikeTool.Archive.self))

        let command = try ExampleXcodebuildLikeTool()
            .with(\.workspace, "ExampleApp.xcworkspace")
            .with(\.scheme, "ExampleApp")
            .with(\.destination, "generic/platform=iOS")
            .with(\.derivedDataPath, ".build/DerivedData")
            .archive()
            .with(\.archivePath, ".build/ExampleApp.xcarchive")
            .with(\.allowProvisioningUpdates, true)
            .invocation

        #expect(
            command == "xcodebuild archive -workspace ExampleApp.xcworkspace -scheme ExampleApp -destination generic/platform=iOS -derivedDataPath .build/DerivedData -archivePath .build/ExampleApp.xcarchive -allowProvisioningUpdates"
        )
    }

    @Test
    func subcommandMacroInfersParentCommandForSubcommandsNestedInExtensions() throws {
        #expect(hasInvocationSummaryParentConformance(ExampleXcodebuildLikeTool.Clean.self))

        let command = try ExampleXcodebuildLikeTool()
            .with(\.workspace, "ExampleApp.xcworkspace")
            .with(\.derivedDataPath, ".build/DerivedData")
            .clean()
            .invocation

        #expect(command == "xcodebuild clean -workspace ExampleApp.xcworkspace -derivedDataPath .build/DerivedData")
    }

    @Test
    func invocationSummaryCanModelReleaseNotesPrecedence() throws {
        let fileBackedNotes = try ExampleGitHubTool()
            .with(\.repository, "PreternaturalAI/ExampleApp")
            .release()
            .create()
            .with(\.tagName, "1.2.0")
            .with(\.title, "ExampleApp 1.2.0")
            .with(\.notes, "Ignored because notes-file wins")
            .with(\.notesFile, "CHANGELOG.md")
            .with(\.draft, true)
            .with(\.assets, [".build/ExampleApp.zip", ".build/ExampleApp.dSYM.zip"])
            .invocation

        let generatedNotes = try ExampleGitHubTool()
            .release()
            .create()
            .with(\.tagName, "1.2.1")
            .with(\.generateNotes, true)
            .with(\.prerelease, true)
            .invocation

        #expect(
            fileBackedNotes == "gh --repo PreternaturalAI/ExampleApp release create 1.2.0 --title ExampleApp 1.2.0 --notes-file CHANGELOG.md --draft .build/ExampleApp.zip .build/ExampleApp.dSYM.zip"
        )
        #expect(generatedNotes == "gh release create 1.2.1 --generate-notes --prerelease")
    }
}

#endif
