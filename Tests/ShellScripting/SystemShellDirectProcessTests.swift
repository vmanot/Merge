import Foundation
import ShellScripting
import Testing

struct SystemShellDirectProcessTests {
    @Test
    func directExecutableRunPreservesByteInputAndClosesStandardInput() async throws {
        let input = Data([0x41, 0x00, 0x42])
        let result = try await SystemShell().run(
            executableURL: URL(fileURLWithPath: "/bin/cat"),
            arguments: [],
            input: input
        )

        #expect(result.terminationError == nil)
        #expect(result.stdout == input)
    }

    @Test
    func emptyInputStillProducesEndOfFileForDirectExecutable() async throws {
        let result = try await SystemShell().run(
            executableURL: URL(fileURLWithPath: "/bin/cat"),
            arguments: [],
            input: Data()
        )

        #expect(result.terminationError == nil)
        #expect(result.stdout == Data())
    }

    @Test
    func largeInputIsStreamedAfterLaunchWithoutDeadlockingThePipe() async throws {
        let input = Data(repeating: 0xA5, count: 1_048_576)
        let result = try await SystemShell().run(
            executableURL: URL(fileURLWithPath: "/bin/cat"),
            arguments: [],
            input: input
        )

        #expect(result.terminationError == nil)
        #expect(result.stdout == input)
    }
}
