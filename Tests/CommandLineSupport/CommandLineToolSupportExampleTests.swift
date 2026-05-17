#if os(macOS)

import CommandLineToolSupport
import Foundation
import Testing

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
        #expect(invocation.arguments == [
            "--verbose",
            "-sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk",
            "build",
            "--release",
            "-vv",
            "--no-sandbox",
            "--package-path Fixtures/Example Package",
            "--triple=arm64-apple-macosx15.0",
            "-Xswiftc -DTRACE_IMPORTS -Xswiftc -emit-loaded-module-trace",
            "ExampleCLI ExampleSupport"
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
}

#endif
