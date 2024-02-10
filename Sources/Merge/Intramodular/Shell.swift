//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import AppKit
import Foundation
import Swallow

/// Adapted from https://github.com/intitni/CopilotForXcode
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public final class Shell: @unchecked Sendable {
    private var process: Process?
    private var outputPipe: Pipe?
    private var inputPipe: Pipe?
    
    public var isRunning: Bool {
        process?.isRunning ?? false
    }
        
    public init() {
        
    }
    
    public func stream(
        command: String = "/bin/bash",
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: [String: String]
    ) -> AsyncThrowingStream<String, Error> {
        self.process?.terminate()
        let process = Process()
        self.process = process
        
        process.launchPath = command
        process.currentDirectoryURL = currentDirectoryURL
        process.arguments = arguments
        process.environment = getEnvironmentVariables()
            .merging(environment, uniquingKeysWith: { $1 })
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        self.outputPipe = outputPipe
        
        let inputPipe = Pipe()
        process.standardInput = inputPipe
        self.inputPipe = inputPipe
        
        var continuation: AsyncThrowingStream<String, Error>.Continuation!
        
        let contentStream = AsyncThrowingStream<String, Error> { cont in
            continuation = cont
        }
        
        Task { [continuation, self] in
            let notificationCenter = NotificationCenter.default
            let notifications = notificationCenter.notifications(
                named: FileHandle.readCompletionNotification,
                object: outputPipe.fileHandleForReading
            )
            
            for await notification in notifications {
                let userInfo = notification.userInfo
                
                if
                    let data = userInfo?[NSFileHandleNotificationDataItem] as? Data,
                    let content = String(data: data, encoding: .utf8),
                    !content.isEmpty
                {
                    continuation?.yield(content)
                }
                
                if !(self.process?.isRunning ?? false) {
                    let reason = self.process?.terminationReason ?? .exit
                    let status = self.process?.terminationStatus ?? 1
                    
                    if
                        let output = (self.process?.standardOutput as? Pipe)?.fileHandleForReading
                            .readDataToEndOfFile(),
                        let content = String(data: output, encoding: .utf8),
                        !content.isEmpty
                    {
                        continuation?.yield(content)
                    }
                    
                    if status == 0 {
                        continuation?.finish()
                    } else {
                        continuation?.finish(throwing: TerminationError(
                            reason: reason,
                            status: status
                        ))
                    }
                    break
                }
                
                Task { @MainActor in
                    outputPipe.fileHandleForReading.readInBackgroundAndNotify(forModes: [.common])
                }
            }
        }
        
        Task { @MainActor in
            outputPipe.fileHandleForReading.readInBackgroundAndNotify(forModes: [.common])
        }
        
        do {
            try process.run()
        } catch {
            continuation.finish(throwing: error)
        }
        
        return contentStream
    }
    
    public func run(
        command: String = "/bin/bash",
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: [String: String]
    ) async throws -> String {
        let process = Process()
        
        process.launchPath = command
        process.currentDirectoryURL = currentDirectoryURL
        process.arguments = arguments
        process.environment = getEnvironmentVariables().merging(environment, uniquingKeysWith: { $1 })
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        self.outputPipe = outputPipe
        
        let inputPipe = Pipe()
        process.standardInput = inputPipe
        self.inputPipe = inputPipe
        
        return try await withUnsafeThrowingContinuation { continuation in
            do {
                process.terminationHandler = { process in
                    do {
                        if let data = try outputPipe.fileHandleForReading.readToEnd(),
                           let content = String(data: data, encoding: .utf8)
                        {
                            if process.terminationStatus == 0 {
                                continuation.resume(returning: content)
                            } else {
                                continuation.resume(
                                    throwing: LocalizedTerminationError(
                                        terminationError: .init(
                                            reason: process.terminationReason,
                                            status: process.terminationStatus
                                        ),
                                        errorDescription: content
                                    )
                                )
                            }
                            return
                        }
                        continuation.resume(returning: "")
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func write(input: String) {
        guard let data = input.data(using: .utf8) else {
            return
        }
        
        inputPipe?.fileHandleForWriting.write(data)
        inputPipe?.fileHandleForWriting.closeFile()
    }
    
    public func terminate() async {
        process?.terminate()
        process = nil
    }
    
    private func getEnvironmentVariables() -> [String: String] {
        ProcessInfo.processInfo.environment.merging(["LANG": "en_US.UTF-8"], uniquingKeysWith: { $1 })
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Shell {
    struct LocalizedTerminationError: Error, LocalizedError {
        let terminationError: TerminationError
        let errorDescription: String?
    }
    
    public struct TerminationError: Error {
        public let reason: Process.TerminationReason
        public let status: Int32
    }
}

#endif
