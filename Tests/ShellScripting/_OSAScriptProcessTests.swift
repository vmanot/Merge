//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Testing

@Suite(.disabled("OSAScriptProcess tests are disabled generally."))
struct OSAScriptProcessTests {
    @Test
    func testPropertySettersAndGetters() {
        let process = OSAScriptProcess()

        let testURL = URL(fileURLWithPath: "/usr/bin")
        let testArgs = ["arg1", "arg2"]
        let testEnv = ["KEY": "VALUE"]
        let testOutput = Pipe()

        process.launchPath = "/usr/bin/osascript"
        process.currentDirectoryURL = testURL
        process.arguments = testArgs
        process.environment = testEnv
        process.standardOutput = testOutput
        process.standardError = testOutput

        #expect(process.launchPath == "/usr/bin/osascript")
        #expect(process.currentDirectoryURL == testURL)
        #expect(process.arguments! == testArgs)
        #expect(process.environment! == testEnv)
        #expect(process.standardOutput as? Pipe == testOutput)
        #expect(process.standardError as? Pipe == testOutput)
    }

    /*func testShit() {
        let process = OSAScriptProcess()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-n",
            "/Applications/Google Chrome.app",
            "--args",
            "--load-extension=/Users/vatsal/Library/Developer/Xcode/DerivedData/All-bkitrutrdzcgrbeojryrrgfeapuk/Build/Products/Debug/BrowserExtensionContainer.app/Contents/Resources/chrome-mv3/"
        ]
    }*/

    @Test
    func testSayHello() {
        let process = OSAScriptProcess()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["hello"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        do {
            try process.run()
        } catch {
            Issue.record("Process failed to run: \(error)")
        }

        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }

    @Test
    func testSayHelloUsingAsyncProcess() async throws {
        let process = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/open"),
            arguments: [
                "-n",
                "/Applications/Google Chrome.app",
                "--args",
                "--load-extension=/Users/vatsal/Library/Developer/Xcode/DerivedData/All-bkitrutrdzcgrbeojryrrgfeapuk/Build/Products/Debug/BrowserExtensionContainer.app/Contents/Resources/chrome-mv3/"
            ],
            options: [._useAppleScript]
        )


        do {
            try await process.run()
        } catch {
            Issue.record("Process failed to run: \(error)")
        }
    }

    @Test
    func testRunMethodWithUnsetExecutableURLShouldThrow() {
        let process = OSAScriptProcess()
        // Not setting executableURL should lead to an error when trying to run the process
        do {
            try process.run()
            Issue.record("Expected to throw an error when executableURL is nil")
        } catch let error as OSAScriptProcess.Error {
            #expect(error == .executablePathMissing)
        } catch {
            Issue.record("Error (\(error)) should be of type OSAScriptProcess.Error")
        }
    }

    // Additional tests could include mocking the underlying Process to verify the correct script is passed to osascript, etc.
}
