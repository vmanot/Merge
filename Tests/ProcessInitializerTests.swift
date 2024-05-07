//
// Copyright (c) Vatsal Manot
//

@testable import Shell
import XCTest

class ShellProcessTests: XCTestCase {
    func testSimpleCommand() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/echo")
        process.arguments = ["Hello, World!"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        try? process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        XCTAssertEqual(output, "Hello, World!")
    }
    
    func testArgumentsWithSpaces() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/echo")
        process.arguments = ["Hello", "World", "with", "spaces"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        try? process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        XCTAssertEqual(output, "Hello World with spaces")
    }

    func testShellEnvironment() {
        let bashCommand = "echo 'Hello, World!'"
        let zshCommand = "ls -l"
        let noShellCommand = "/bin/ls"
        
        let bashProcess = Process(command: bashCommand, shell: .bash)
        let zshProcess = Process(command: zshCommand, shell: .zsh)
        let noShellProcess = Process(command: noShellCommand, shell: .none)
        
        XCTAssertEqual(bashProcess.executableURL!.path, "/bin/bash")
        XCTAssertEqual(bashProcess.arguments, ["-l", "-c", bashCommand])
        
        XCTAssertEqual(zshProcess.executableURL!.path, "/bin/zsh")
        XCTAssertEqual(zshProcess.arguments, ["-l", "-c", zshCommand])
        
        XCTAssertEqual(noShellProcess.executableURL!.path, noShellCommand)
        XCTAssertEqual(noShellProcess.arguments, [])
    }
    
    func testArgumentEscaping() {
        let plainArgument = Process.ArgumentLiteral("Hello")
        let quotedArgument = Process.ArgumentLiteral("Hello, World!", isQuoted: true)
        let nestedQuotesArgument = Process.ArgumentLiteral("echo \"John said, 'Hello'\"", isQuoted: true)
        
        XCTAssertEqual(plainArgument.escapedValue, "Hello")
        XCTAssertEqual(quotedArgument.escapedValue, "\"Hello, World!\"")
        XCTAssertEqual(nestedQuotesArgument.escapedValue, "\"echo \\\"John said, 'Hello'\\\"\"")
    }
    
    func testProcessInitialization() {
        let command = "echo 'Hello, World!'"
        let arguments = [Process.ArgumentLiteral("arg1"), Process.ArgumentLiteral("arg2", isQuoted: true)]
        let environment = ["ENV_VAR": "value"]
        let currentDirectory = "/path/to/directory"
        
        let process = Process(
            command: command,
            shell: .bash,
            arguments: arguments,
            environment: environment,
            currentDirectoryPath: currentDirectory
        )
        
        XCTAssertEqual(process.executableURL!.path, "/bin/bash")
        XCTAssertEqual(process.arguments, ["-l", "-c", command, "arg1", "\"arg2\""])
        XCTAssertEqual(process.environment?["ENV_VAR"], "value")
        XCTAssertEqual(process.currentDirectoryURL?.path, currentDirectory)
    }
    
    func testSplitArguments() {
        let arguments = "arg1 \"arg2 with spaces\" 'arg3 with \"nested quotes\"' /path/to/file\\ with\\ spaces.txt"
        
        let expectedArguments = [
            "arg1",
            "\"arg2 with spaces\"",
            "'arg3 with \"nested quotes\"'",
            "/path/to/file\\ with\\ spaces.txt"
        ]
        
        let splitArguments = Process.splitArguments(arguments)
        
        XCTAssertEqual(splitArguments, expectedArguments)
    }
    
    func testBashShellPathAndArguments() {
        let bash = Process.ShellEnvironment.bash
        let result = bash.shellPathAndArguments(command: "echo Hello")
        
        XCTAssertEqual(result.path, URL(fileURLWithPath: "/bin/bash"))
        XCTAssertEqual(result.arguments, ["-l", "-c", "echo Hello"])
    }
    
    func testZshShellPathAndArguments() {
        let zsh = Process.ShellEnvironment.zsh
        let result = zsh.shellPathAndArguments(command: "echo Hello")
        
        XCTAssertEqual(result.path, URL(fileURLWithPath: "/bin/zsh"))
        XCTAssertEqual(result.arguments, ["-l", "-c", "echo Hello"])
    }
    
    func testNoneShellPathAndArguments() {
        let none = Optional<Process.ShellEnvironment>.none
        let result = none.shellPathAndArguments(command: "/usr/local/bin/custom")
        
        XCTAssertEqual(result.path, URL(fileURLWithPath: "/usr/local/bin/custom"))
        XCTAssertTrue(result.arguments.isEmpty)
    }
    
    func testSplitArgumentsWithMixedContent() {
        let command = "run --path=\"/Applications/My App.app\" --quiet"
        let result = Process.splitArguments(command)
        
        XCTAssertEqual(result, ["run", "--path=\"/Applications/My App.app\"", "--quiet"])
    }
    
    func testArgumentString1() {
        let command = "printenv"
        let argumentString = "VAR1 VAR2"
        let environment = ["VAR1": "Value1", "VAR2": "Value2"]
        let process = Process(
            command: command,
            argumentString: argumentString,
            environment: environment
        )
        
        XCTAssertEqual(process.arguments, ["-l", "-c", "printenv", "VAR1", "VAR2"])
        XCTAssertEqual(process.environment?["VAR1"], "Value1")
        XCTAssertEqual(process.environment?["VAR2"], "Value2")
    }
    
    func testArgumentString2() {
        // Test case 3: Process initialization with command, arguments, and current directory
        let command = "ls"
        let argumentString = "-l -a"
        let currentDirectory = "/Users/username/Documents"
        let process = Process(
            command: command,
            argumentString: argumentString,
            currentDirectoryPath: currentDirectory
        )

        XCTAssertEqual(process.arguments, ["-l", "-c", "ls", "-l", "-a"])
        XCTAssertEqual(process.currentDirectoryURL?.path, currentDirectory)
    }
}
