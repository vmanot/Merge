//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Cocoa
import System

extension Pipe {
    /// Obtains a `FILE` pointer for the pipe's read or write end.
    ///
    /// - Parameters:
    ///   - mode: The mode in which to open the `FILE` pointer. Use "r" for reading or "w" for writing.
    /// - Returns: A `FILE` pointer for the specified end of the pipe, or `nil` if an error occurred.
    func filePointer(mode: String) -> UnsafeMutablePointer<FILE>? {
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
        
        assert(fileDescriptor._isOpen)
        
        return fdopen(rawFileDescriptor, mode)
    }
}

extension FileDescriptor {
    public var _isOpen: Bool {
        var statBuffer = stat()
        return fstat(self.rawValue, &statBuffer) == 0
    }
}

#endif
