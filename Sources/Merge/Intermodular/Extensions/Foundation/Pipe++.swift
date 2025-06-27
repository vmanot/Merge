//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

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

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Pipe {
    public var _fileDescriptorForReading: FileDescriptor {
        FileDescriptor(rawValue: fileHandleForReading.fileDescriptor)
    }
    
    public var _fileDescriptorForWriting: FileDescriptor {
        FileDescriptor(rawValue: fileHandleForWriting.fileDescriptor)
    }
}

extension Pipe {
    /// Asynchronously reads the available data from the pipe until EOF.
    @discardableResult
    func _readToEnd(
        receiveData: @escaping (Data) async throws -> Void
    ) async throws -> Data {
        let queue = ThrowingTaskQueue()
        let fileHandle = self.fileHandleForReading
        
        @MutexProtected
        var didExit: Bool = false
        @MutexProtected
        var result = Data()
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            fileHandle.readabilityHandler = { fileHandle in
                guard !$didExit.assignedValue else {
                    return
                }
                
                let data = fileHandle.availableData
                
                if data.isEmpty {
                    $didExit.assignedValue = true
                    
                    continuation.resume()
                } else {
                    queue.addTask {
                        try await receiveData(data)
                    }
                    
                    $result.withCriticalRegion {
                        $0.append(data)
                    }
                }
            }
        }
        
        fileHandle.readabilityHandler = nil
        
        try await queue.waitForAll()
        
        return result
    }
}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension FileDescriptor {
    public var _isOpen: Bool {
        var statBuffer = stat()
        
        return fstat(self.rawValue, &statBuffer) == 0
    }
}
