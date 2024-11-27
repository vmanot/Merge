//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System

public enum _ProcessStandardOutputSink: Hashable {
    /// Redirect output to the terminal.
    case terminal
    /// Redirect output to the file at the given path, creating if necessary.
    case filePath(_ path: String)
    /// Redirect output and error streams to the files at the given paths, creating if necessary.
    case split(_ out: String, err: String)
    /// The null device, also known as `/dev/null`.
    case null
}

#if os(macOS)
extension Process {
    public typealias StandardOutputSink = _ProcessStandardOutputSink
}

// MARK: - Initializers

extension Process.StandardOutputSink {
    public static func file(
        _ url: URL
    ) -> Self {
        Self.filePath(url._fromFileURLToURL().path)
    }
}

// MARK: - Supplementary

extension Process {
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public func redirectAllOutput(
        to sink: Process.StandardOutputSink
    ) throws {
        switch sink {
            case .terminal:
                self.standardOutput = FileHandle.standardOutput
                self.standardError = FileHandle.standardError
            case .filePath(let path):
                let fileHandle: FileHandle = try self._createFile(atPath: path)
                
                self.standardOutput = fileHandle
                self.standardError = fileHandle
            case .split(let outputPath, let errorPath):
                self.standardOutput = try self._createFile(atPath: outputPath)
                self.standardError = try self._createFile(atPath: errorPath)
            case .null:
                self.standardOutput = FileHandle.nullDevice
                self.standardError = FileHandle.nullDevice
        }
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func _createFile(
        atPath path: String
    ) throws -> FileHandle {
        let directories = FilePath(path).lexicallyNormalized().removingLastComponent()
        
        try FileManager.default.createDirectory(atPath: directories.string, withIntermediateDirectories: true)
        
        guard FileManager.default.createFile(atPath: path, contents: Data()) else {
            struct CouldNotCreateFile: Error {
                let path: String
            }
            
            throw CouldNotCreateFile(path: path)
        }
        
        guard let fileHandle = FileHandle(forWritingAtPath: path) else {
            struct CouldNotOpenFileForWriting: Error {
                let path: String
            }
            
            throw CouldNotOpenFileForWriting(path: path)
        }
        
        return fileHandle
    }
}

#endif
