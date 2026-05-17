//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public actor _StandardInputOutputStreamsBuffer {
    private var standardOutputBuffer: Data = Data()
    private var standardErrorBuffer: Data = Data()
    private var fileHandles: [String: FileHandle] = [:]
    private let publishers: _AsyncProcess._Publishers
    private let options: Set<_AsyncProcess.Option>

    init(publishers: _AsyncProcess._Publishers, options: Set<_AsyncProcess.Option>) {
        self.publishers = publishers
        self.options = options
    }

    func record(
        data: Data,
        forPipe pipe: Pipe,
        pipeName: _ProcessPipeName
    ) async {
        guard !data.isEmpty else {
            return
        }

        switch pipeName {
            case .standardOutput:
                publishers.standardOutputPublisher.send(data)
            case .standardError:
                publishers.standardErrorPublisher.send(data)
            default:
                break
        }

        _record(data: data, forPipe: pipeName)

        await forwardIfNecessary(data: data, forPipe: pipeName)
    }

    private func forwardIfNecessary(
        data: Data,
        forPipe pipe: _ProcessPipeName
    ) async {
        for sink in options.map(\._stdoutStderrSink) {
            do {
                try forward(data: data, forPipe: pipe, to: sink)
            } catch {
                runtimeIssue(error)
            }
        }
    }

    private func forward(
        data: Data,
        forPipe pipe: _ProcessPipeName,
        to sink: _ProcessStandardOutputSink
    ) throws {
        switch sink {
            case .terminal:
                switch pipe {
                    case .standardOutput:
                        FileHandle.standardOutput.write(data)
                    case .standardError:
                        FileHandle.standardError.write(data)
                    default:
                        break
                }
            case .filePath(let path):
                guard pipe == .standardOutput || pipe == .standardError else {
                    return
                }

                try fileHandle(forPath: path).write(contentsOf: data)
            case .split(let outputPath, let errorPath):
                switch pipe {
                    case .standardOutput:
                        try fileHandle(forPath: outputPath).write(contentsOf: data)
                    case .standardError:
                        try fileHandle(forPath: errorPath).write(contentsOf: data)
                    default:
                        break
                }
            case .null:
                break
        }
    }

    private func fileHandle(
        forPath path: String
    ) throws -> FileHandle {
        if let existing = fileHandles[path] {
            return existing
        }

        let url = URL(fileURLWithPath: path)

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(atPath: path) {
            _ = FileManager.default.createFile(atPath: path, contents: nil)
        }

        let result = try FileHandle(forWritingTo: url)

        try result.truncate(atOffset: 0)

        fileHandles[path] = result

        return result
    }

    func closeFileHandles() {
        for handle in fileHandles.values {
            do {
                try handle.close()
            } catch {
                runtimeIssue(error)
            }
        }

        fileHandles.removeAll()
    }

    private func _record(
        data: Data,
        forPipe pipe: _ProcessPipeName
    ) {
        assert(!data.isEmpty)

        switch pipe {
            case .standardOutput:
                standardOutputBuffer += data
            case .standardError:
                standardErrorBuffer += data
            case .standardInput:
                assertionFailure()

                break
        }
    }

    func _standardOutputStringUsingUTF8() throws -> String {
        try standardOutputBuffer.toString(encoding: .utf8)
    }

    func _standardErrorStringUsingUTF8() throws -> String {
        try standardErrorBuffer.toString(encoding: .utf8)
    }
}
