//
// Copyright (c) Vatsal Manot
//

import Darwin
import Foundation
import Swift

public class _StandardOutputRewriter: @unchecked Sendable {
    private var originalSTDOUTDescriptor: Int32 = -1
    private var originalSTDERRDescriptor: Int32 = -1
    private let stdoutPipe: Pipe = Pipe()
    private let stderrPipe: Pipe = Pipe()
    private let modifyLine: @Sendable (String) -> String?
    
    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()
    
    private var runLoop: RunLoop?
    private var isRunning = false
    private var stopContinuation: CheckedContinuation<Void, Never>?
    private let hasRunLoop: Bool
    
    public init(
        modifyLine: @escaping @Sendable (String) -> String?
    ) {
        self.modifyLine = modifyLine
        self.hasRunLoop = _StandardOutputRewriter.checkRunLoopAvailability()

        start()
    }
        
    public func start() {
        guard originalSTDERRDescriptor == -1 && originalSTDERRDescriptor == -1 else {
            return
        }
        
        originalSTDOUTDescriptor = dup(STDOUT_FILENO)
        originalSTDERRDescriptor = dup(STDERR_FILENO)
        
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        
        dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        
        isRunning = true
        
        
        if !hasRunLoop {
            // Start a background thread for the RunLoop if we don't have one
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else { return }
                
                self.runLoop = RunLoop.current
                self.observePipe(self.stdoutPipe.fileHandleForReading, isStdout: true)
                self.observePipe(self.stderrPipe.fileHandleForReading, isStdout: false)
                
                while self.isRunning {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                
                // Signal completion when the run loop exits
                if let continuation = self.stopContinuation {
                    self.stopContinuation = nil
                    continuation.resume()
                }
            }
        } else {
            // Use existing run loop
            observePipe(stdoutPipe.fileHandleForReading, isStdout: true)
            observePipe(stderrPipe.fileHandleForReading, isStdout: false)
        }
    }
    
    public func stop() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            isRunning = false
            
            if !hasRunLoop {
                // If we created our own run loop, wait for it to finish
                stopContinuation = continuation
            } else {
                // If using existing run loop, clean up immediately
                cleanup()
                continuation.resume()
            }
        }
    }
    
    private func cleanup() {
        flushBuffers()
        
        if originalSTDOUTDescriptor != -1 {
            dup2(originalSTDOUTDescriptor, STDOUT_FILENO)
            close(originalSTDOUTDescriptor)
            originalSTDOUTDescriptor = -1
        }
        if originalSTDERRDescriptor != -1 {
            dup2(originalSTDERRDescriptor, STDERR_FILENO)
            close(originalSTDERRDescriptor)
            originalSTDERRDescriptor = -1
        }
        
        stdoutPipe.fileHandleForReading.closeFile()
        stdoutPipe.fileHandleForWriting.closeFile()
        stderrPipe.fileHandleForReading.closeFile()
        stderrPipe.fileHandleForWriting.closeFile()
    }
    
    private func observePipe(_ pipe: FileHandle, isStdout: Bool) {
        NotificationCenter.default.addObserver(
            forName: .NSFileHandleDataAvailable,
            object: pipe,
            queue: nil
        ) { [weak self] (notification: Notification) in
            guard let self = self,
                  let fileHandle = notification.object as? FileHandle else {
                return
            }
            
            let data: Data = fileHandle.availableData
            
            if data.isEmpty {
                return
            }
            
            let buffer: Data = isStdout ? self.stdoutBuffer : self.stderrBuffer
        
            self.processData(data, buffer: buffer, isStdout: isStdout)
            
            if self.isRunning {
                pipe.waitForDataInBackgroundAndNotify()
            }
        }
        
        pipe.waitForDataInBackgroundAndNotify()
    }
    
    private func processData(
        _ data: Data,
        buffer: Data,
        isStdout: Bool
    ) {
        var buffer: Data = buffer
        buffer.append(data)
        
        while let range = buffer.range(of: Data("\n".utf8)) {
            let lineData = buffer.subdata(in: 0..<range.upperBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if let line = String(data: lineData, encoding: .utf8),
               let modifiedLine = modifyLine(line) {
                let fileHandle = FileHandle(fileDescriptor: isStdout ? originalSTDOUTDescriptor : originalSTDERRDescriptor)
                
                fileHandle.write(modifiedLine.data(using: .utf8) ?? Data())
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
            FileHandle(fileDescriptor: originalSTDOUTDescriptor).write(modifiedLine.data(using: .utf8) ?? Data())
        }
        
        if let modifiedLine = modifyLine(String(data: stderrBuffer, encoding: .utf8) ?? "") {
            FileHandle(fileDescriptor: originalSTDERRDescriptor).write(modifiedLine.data(using: .utf8) ?? Data())
        }
        
        stdoutBuffer = Data()
        stderrBuffer = Data()
    }
    
    deinit {
        // Since deinit can't be async, we'll just do immediate cleanup
        isRunning = false
        cleanup()
    }
}

extension _StandardOutputRewriter {
    private static func checkRunLoopAvailability() -> Bool {
        let currentRunLoop = CFRunLoopGetCurrent()
        let result: Bool
        
        if let modes = CFRunLoopCopyAllModes(currentRunLoop) as? [String], !modes.isEmpty {
            let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0) { observer, activity in
                CFRunLoopObserverInvalidate(observer)
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
            
            if let observer = observer {
                CFRunLoopAddObserver(currentRunLoop, observer, CFRunLoopMode.defaultMode)
                
                let ranLoop = CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1, true) != CFRunLoopRunResult.finished
                
                CFRunLoopRemoveObserver(currentRunLoop, observer, CFRunLoopMode.defaultMode)
                
                result = ranLoop
            } else {
                result = false
            }
        } else {
            result = false
        }
        
        return result
    }
    
    public static func checkEnvironment() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: checkRunLoopAvailability())
            }
        }
    }
}

// MARK: - Helpers

extension String {
    public var _filteringAppleConsoleOutputCrap: String? {
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
