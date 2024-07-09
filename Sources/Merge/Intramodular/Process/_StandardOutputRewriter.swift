//
// Copyright (c) Vatsal Manot
//

import Darwin
import Foundation
import Swift

public class _StandardOutputRewriter {
    private var originalSTDOUTDescriptor: Int32 = -1
    private var originalSTDERRDescriptor: Int32 = -1
    private let stdoutPipe: Pipe = Pipe()
    private let stderrPipe: Pipe = Pipe()
    private let modifyLine: (String) -> String?
    
    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()
    
    public init(modifyLine: @escaping (String) -> String?) {
        self.modifyLine = modifyLine
        
        start()
    }
    
    public func start() {
        originalSTDOUTDescriptor = dup(STDOUT_FILENO)
        originalSTDERRDescriptor = dup(STDERR_FILENO)
        
        dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        
        observePipe(stdoutPipe.fileHandleForReading, isStdout: true)
        observePipe(stderrPipe.fileHandleForReading, isStdout: false)
    }
    
    public func stop() {
        flushBuffers()
        
        if originalSTDOUTDescriptor != -1 {
            dup2(originalSTDOUTDescriptor, STDOUT_FILENO)
            close(originalSTDOUTDescriptor)
        }
        if originalSTDERRDescriptor != -1 {
            dup2(originalSTDERRDescriptor, STDERR_FILENO)
            close(originalSTDERRDescriptor)
        }
    }
    
    private func observePipe(
        _ pipe: FileHandle,
        isStdout: Bool
    ) {
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: pipe, queue: nil) { notification in
            guard let fileHandle = notification.object as? FileHandle else { return }
            let data = fileHandle.availableData
            if data.isEmpty { return }
            
            let buffer = isStdout ? self.stdoutBuffer : self.stderrBuffer
            self.processData(data, buffer: buffer, isStdout: isStdout)
            
            pipe.waitForDataInBackgroundAndNotify()
        }
        pipe.waitForDataInBackgroundAndNotify()
    }
    
    private func processData(
        _ data: Data,
        buffer: Data,
        isStdout: Bool
    ) {
        var buffer = buffer
        buffer.append(data)
        
        while let range = buffer.range(of: Data("\n".utf8)) {
            let lineData = buffer.subdata(in: 0..<range.upperBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if let line = String(data: lineData, encoding: .utf8), let modifiedLine = modifyLine(line) {
                FileHandle(fileDescriptor: isStdout ? self.originalSTDOUTDescriptor : self.originalSTDERRDescriptor).write(modifiedLine.data(using: .utf8) ?? Data())
            }
        }
        
        if isStdout {
            stdoutBuffer = buffer
        } else {
            stderrBuffer = buffer
        }
    }
    
    private func flushBuffers() {
        if let modifiedLine = modifyLine(String(data: stdoutBuffer, encoding: .utf8) ?? "") {
            FileHandle(fileDescriptor: self.originalSTDOUTDescriptor).write(modifiedLine.data(using: .utf8) ?? Data())
        }
        if let modifiedLine = modifyLine(String(data: stderrBuffer, encoding: .utf8) ?? "") {
            FileHandle(fileDescriptor: self.originalSTDERRDescriptor).write(modifiedLine.data(using: .utf8) ?? Data())
        }
        stdoutBuffer = Data()
        stderrBuffer = Data()
    }
    
    deinit {
        stop()
    }
}

extension String {
    var _filteringAppleConsoleOutputCrap: String? {
        if hasPrefix("_NSPersistentUIDeleteItemAtFileURL(NSURL *const __strong)") {
            return nil
        }
        
        if hasPrefix("_NSPersistentUIDeleteItemAtFileURL(NSURL *const __strong)") {
            return nil
        }
        
        if contains("One of the two will be used. Which one is undefined") {
            return nil
        }
        
        if contains("Failed to inherit CoreMedia permissions from") {
            return nil
        }
        
        if contains("Could not signal service com.apple.WebKit.WebContent") {
            return nil
        }
        
        if contains("[Assert] Attempting to create an image with an unknown type") {
            return nil
        }
        
        if contains("[core] 'Error returned from daemon'") {
            return nil
        }
        
        if contains("[plugin] AddInstanceForFactory") {
            return nil
        }
        
        if contains("[Core] unable to attach (null) to pid") {
            return nil
        }
        
        if contains("_BSMachError: (os/kern) invalid capability (20)") {
            return nil
        }
        
        return self
    }
}
