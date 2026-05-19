//
// Copyright (c) Vatsal Manot
//

@testable import ShellScripting

import Foundation
import Testing

@Suite
struct ShellProcessTests {
    @Test
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

        #expect(output == "Hello, World!")
    }

    @Test
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

        #expect(output == "Hello World with spaces")
    }

    @Test
    func testPreferredUNIXShellName() {
        let bashCommand = "echo 'Hello, World!'"
        let zshCommand = "ls -l"
        let noShellCommand = "/bin/ls"

        let bashProcess = Process(command: bashCommand, shell: .bash)
        let zshProcess = Process(command: zshCommand, shell: .zsh)
        let noShellProcess = Process(command: noShellCommand, shell: .none)

        #expect(bashProcess.executableURL!.path == "/bin/bash")
        #expect(bashProcess.arguments == ["-l", "-c", bashCommand])

        #expect(zshProcess.executableURL!.path == "/bin/zsh")
        #expect(zshProcess.arguments == ["-l", "-c", zshCommand])

        #expect(noShellProcess.executableURL!.path == noShellCommand)
        #expect(noShellProcess.arguments == [])
    }

    @Test
    func testArgumentEscaping() {
        let plainArgument = Process.ArgumentLiteral("Hello")
        let quotedArgument = Process.ArgumentLiteral("Hello, World!", isQuoted: true)
        let nestedQuotesArgument = Process.ArgumentLiteral("echo \"John said, 'Hello'\"", isQuoted: true)

        #expect(plainArgument.rawValue == "Hello")
        #expect(plainArgument.posixShellEscapedValue == "Hello")
        #expect(quotedArgument.posixShellEscapedValue == "\"Hello, World!\"")
        #expect(nestedQuotesArgument.posixShellEscapedValue == "\"echo \\\"John said, 'Hello'\\\"\"")
    }

    @Test
    func testArgumentLiteralStorageViews() {
        let stringArgument = Process.ArgumentLiteral("Hello")
        let rawBytesArgument = Process.ArgumentLiteral(rawBytes: Array("Hello".utf8))

        #expect(stringArgument.storage == .string("Hello"))
        #expect(stringArgument.stringValue == "Hello")
        #expect(stringArgument.rawBytes == Array("Hello".utf8))
        #expect(rawBytesArgument.storage == .rawBytes(Array("Hello".utf8)))
        #expect(rawBytesArgument.stringValue == "Hello")
        #expect(rawBytesArgument.rawValue == "Hello")
    }

    @Test
    func testArgumentLiteralRawBytesCanRepresentNonUTF8Values() {
        let argument = Process.ArgumentLiteral(rawBytes: [0xff])

        #expect(argument.storage == .rawBytes([0xff]))
        #expect(argument.stringValue == nil)
        #expect(argument.rawBytes == [0xff])
    }

    @Test
    func testArgumentLiteralHasUsefulDebugReflection() {
        let argument = Process.ArgumentLiteral("Hello, World!", isQuoted: true)
        let mirrorLabels = Array(Mirror(reflecting: argument).children).map(\.label)

        #expect(argument.description == "Hello, World!")
        #expect(argument.debugDescription.contains("Process.ArgumentLiteral(.string(\"Hello, World!\""))
        #expect(mirrorLabels == ["storage", "stringValue", "rawValue", "rawBytes", "options", "isQuoted"])
    }

    @Test
    func testArgumentLiteralShellDialectRendering() {
        let argument = Process.ArgumentLiteral("Hello, World!", isQuoted: true)

        #expect(argument.escapedValue(for: .posix) == argument.posixShellEscapedValue)
    }

    @Test
    func testArgumentLiteralURLRepresentation() {
        let url = URL(fileURLWithPath: "/tmp/Some File")

        #expect(Process.ArgumentLiteral(url).rawValue == "/tmp/Some File")
        #expect(Process.ArgumentLiteral(url, representation: .absoluteString).rawValue == "file:///tmp/Some%20File")
    }

    @Test
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

        #expect(process.executableURL!.path == "/bin/bash")
        #expect(process.arguments == ["-l", "-c", command, "arg1", "\"arg2\""])
        #expect(process.environment?["ENV_VAR"] == "value")
        #expect(process.currentDirectoryURL?.path == currentDirectory)
    }

    @Test
    func testSplitArguments() {
        let arguments = "arg1 \"arg2 with spaces\" 'arg3 with \"nested quotes\"' /path/to/file\\ with\\ spaces.txt"

        let expectedArguments = [
            "arg1",
            "\"arg2 with spaces\"",
            "'arg3 with \"nested quotes\"'",
            "/path/to/file\\ with\\ spaces.txt"
        ]

        let splitArguments = Process.splitArguments(arguments)

        #expect(splitArguments == expectedArguments)
    }

    @Test
    func testBashShellPathAndArguments() {
        let bash = PreferredUNIXShell.Name.bash
        let result = bash.deriveExecutableURLAndArguments(fromCommand: "echo Hello")

        #expect(result.executableURL == URL(fileURLWithPath: "/bin/bash"))
        #expect(result.arguments == ["-l", "-c", "echo Hello"])
    }

    @Test
    func testZshShellPathAndArguments() {
        let zsh = PreferredUNIXShell.Name.zsh
        let result = zsh.deriveExecutableURLAndArguments(fromCommand: "echo Hello")

        #expect(result.executableURL == URL(fileURLWithPath: "/bin/zsh"))
        #expect(result.arguments == ["-l", "-c", "echo Hello"])
    }

    @Test
    func testNoneShellPathAndArguments() {
        let none = Optional<PreferredUNIXShell.Name>.none
        let result = none.deriveExecutableURLAndArguments(fromCommand: "/usr/local/bin/custom")

        #expect(result.executableURL == URL(fileURLWithPath: "/usr/local/bin/custom"))
        #expect(result.arguments.isEmpty)
    }

    @Test
    func testSplitArgumentsWithMixedContent() {
        let command = "run --path=\"/Applications/My App.app\" --quiet"
        let result = Process.splitArguments(command)

        #expect(result == ["run", "--path=\"/Applications/My App.app\"", "--quiet"])
    }

    @Test
    func testArgumentString1() {
        let command = "printenv"
        let argumentString = "VAR1 VAR2"
        let environment = ["VAR1": "Value1", "VAR2": "Value2"]
        let process = Process(
            command: command,
            argumentString: argumentString,
            environment: environment
        )

        #expect(process.arguments == ["-l", "-c", "printenv", "VAR1", "VAR2"])
        #expect(process.environment?["VAR1"] == "Value1")
        #expect(process.environment?["VAR2"] == "Value2")
    }

    @Test
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

        #expect(process.arguments == ["-l", "-c", "ls", "-l", "-a"])
        #expect(process.currentDirectoryURL?.path == currentDirectory)
    }
}
