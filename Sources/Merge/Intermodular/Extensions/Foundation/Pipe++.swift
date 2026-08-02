//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

#if !targetEnvironment(macCatalyst)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension Pipe {
    /// Obtains a `FILE` pointer for the pipe's read or write end.
    ///
    /// - Parameters:
    ///   - mode: The mode in which to open the `FILE` pointer. Use "r" for reading or "w" for writing.
    /// - Returns: A `FILE` pointer for the specified end of the pipe, or `nil` if an error occurred.
    func filePointer(
        mode: String
    ) -> UnsafeMutablePointer<FILE>? {
        let rawFileDescriptor: Int32
        
        // Determine the file descriptor based on the mode
        switch mode {
            case "r":
                rawFileDescriptor = self.fileHandleForReading.fileDescriptor
            case "w":
                rawFileDescriptor = self.fileHandleForWriting.fileDescriptor
            default:
                assertionFailure("Unsupported mode: \(mode). Use 'r' for reading or 'w' for writing.")
                
                return nil
        }
        
        let fileDescriptor = FileDescriptor(rawValue: rawFileDescriptor)
        let descriptor: UnsafeMutablePointer<FILE>? = fdopen(rawFileDescriptor, mode)
        
        if !fileDescriptor._isOpen {
            runtimeIssue("Failed to open file descriptor for mode: \(mode)")
        }
        
        return descriptor
    }
}
#endif

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst 14.0, *)
extension Pipe {
    public var _fileDescriptorForReading: FileDescriptor {
        FileDescriptor(rawValue: fileHandleForReading.fileDescriptor)
    }
    
    public var _fileDescriptorForWriting: FileDescriptor {
        FileDescriptor(rawValue: fileHandleForWriting.fileDescriptor)
    }
}

extension Pipe {
    final class _AsyncReader: @unchecked Sendable {
        private let fileHandle: FileHandle
        private let stream: AsyncStream<Data>
        private let continuation: AsyncStream<Data>.Continuation

        @MutexProtected
        private var didFinish = false

        init(fileHandle: FileHandle) {
            self.fileHandle = fileHandle
            (self.stream, self.continuation) = AsyncStream<Data>.makeStream()

            fileHandle.readabilityHandler = { [weak self] handle in
                self?.receiveData(from: handle)
            }
        }

        deinit {
            finish()
        }

        func readToEnd(
            receiveData: @escaping (Data) async throws -> Void
        ) async throws -> Data {
            try await withTaskCancellationHandler {
                var result = Data()

                for await data in stream {
                    result.append(data)
                    try await receiveData(data)
                }

                return result
            } onCancel: {
                cancel()
            }
        }

        private func cancel() {
            finish()
        }

        private func receiveData(from handle: FileHandle) {
            var reachedEndOfFile = false

            $didFinish.withCriticalRegion { didFinish in
                guard !didFinish else {
                    return
                }

                let data = handle.availableData

                if data.isEmpty {
                    didFinish = true
                    reachedEndOfFile = true
                } else {
                    continuation.yield(data)
                }
            }

            if reachedEndOfFile {
                handle.readabilityHandler = nil
                continuation.finish()
            }
        }

        private func finish() {
            var shouldFinish = false

            $didFinish.withCriticalRegion { didFinish in
                guard !didFinish else {
                    return
                }

                didFinish = true
                shouldFinish = true
            }

            guard shouldFinish else {
                return
            }

            fileHandle.readabilityHandler = nil
            continuation.finish()
        }
    }

    func _makeAsyncReader() -> _AsyncReader {
        _AsyncReader(fileHandle: fileHandleForReading)
    }

    /// Asynchronously reads the available data from the pipe until EOF.
    @discardableResult
    func _readToEnd(
        receiveData: @escaping (Data) async throws -> Void
    ) async throws -> Data {
        try await _makeAsyncReader().readToEnd(receiveData: receiveData)
    }
}

#if !targetEnvironment(macCatalyst)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension FileDescriptor {
    public var _isOpen: Bool {
        var statBuffer = Darwin.stat()
        
        return fstat(self.rawValue, &statBuffer) == 0
    }
}
#endif
