//
// Copyright (c) Vatsal Manot
//

@testable import Merge
import XCTest

class OSAScriptProcessTests: XCTestCase {
    
    func testPropertySettersAndGetters() {
        let process = _OSAScriptProcess()
        
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
    
   /* func testRunMethod() {
        let process = _OSAScriptProcess()
        
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
    }*/
    
    func testRunMethodWithUnsetExecutableURLShouldThrow() {
        let process = _OSAScriptProcess()
        // Not setting executableURL should lead to an error when trying to run the process
        XCTAssertThrowsError(try process.run(), "Expected to throw an error when executableURL is nil") { error in
            guard let err = error as NSError? else {
                XCTFail("Error should be of type NSError")
                return
            }
            XCTAssertEqual(err.domain, "OSAScriptProcessError")
            XCTAssertEqual(err.code, 0)
            XCTAssertEqual(err.userInfo[NSLocalizedDescriptionKey] as? String, "Executable URL is not set.")
        }
    }
    
    // Additional tests could include mocking the underlying Process to verify the correct script is passed to osascript, etc.
}
