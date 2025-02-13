//
// Copyright (c) Vatsal Manot
//

@testable import Merge
import XCTest

class OSAScriptProcessTests: XCTestCase {
    
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
        
        XCTAssertEqual(process.launchPath, "/usr/bin/osascript")
        XCTAssertEqual(process.currentDirectoryURL, testURL)
        XCTAssertEqual(process.arguments!, testArgs)
        XCTAssertEqual(process.environment!, testEnv)
        XCTAssertEqual(process.standardOutput as? Pipe, testOutput)
        XCTAssertEqual(process.standardError as? Pipe, testOutput)
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
    
    func testSayHello() {
        let process = OSAScriptProcess()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["hello"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
        } catch {
            XCTFail("Process failed to run: \(error)")
        }
        
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }
    
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
            XCTFail("Process failed to run: \(error)")
        }
    }
    
    func testRunMethodWithUnsetExecutableURLShouldThrow() {
        let process = OSAScriptProcess()
        // Not setting executableURL should lead to an error when trying to run the process
        XCTAssertThrowsError(try process.run(), "Expected to throw an error when executableURL is nil") { error in
            guard let error = error as? OSAScriptProcess.Error else {
                XCTFail("Error (\(error)) should be of type OSAScriptProcess.Error")
                
                return
            }
            
            XCTAssertEqual(error, OSAScriptProcess.Error.executablePathMissing)
        }
    }
    
    // Additional tests could include mocking the underlying Process to verify the correct script is passed to osascript, etc.
}
