//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Foundation
import os

public final class ProcessTask: TaskProtocol {
    public typealias Success = Void
    
    public enum Error: Swift.Error {
        case exitFailure(ProcessExitFailure)
        case unknown(Swift.Error)
    }
    
    public let process: Process
    
    private let base = PassthroughTask<Void, Error>()
    
    private let standardOutputPipe = Pipe()
    private let standardOutputData = PassthroughSubject<Data, Never>()
    private let standardErrorPipe = Pipe()
    private let standardErrorData = PassthroughSubject<Data, Never>()
    
    public var name: TaskName {
        .init(process.processIdentifier)
    }
    
    public var status: TaskStatus<Success, Error> {
        base.status
    }
    
    public var objectWillChange: AnyPublisher<TaskStatus<Success, Error>, Never> {
        base.objectWillChange
    }
    
    public init(process: Process) {
        self.process = process
    }
    
    public func start() {
        setupPipes()
        
        process.terminationHandler = { [weak self] process in
            guard let `self` = self else {
                return
            }
            
            self.teardownPipes()
            
            let terminationStatus = process.terminationStatus
            
            if terminationStatus == 0 {
                self.base.send(.success(()))
            } else {
                self.base.send(.error(.exitFailure(.exit(status: terminationStatus))))
            }
        }
        
        do {
            try process.run()
        } catch {
            base.send(completion: .failure(.unknown(error)))
        }
    }
    
    public func cancel() {
        process.terminate()
        
        base.send(completion: .failure(.canceled))
    }
}

extension ProcessTask {
    private func setupPipes() {
        process.standardOutput = standardOutputPipe
        
        standardOutputPipe.fileHandleForReading.readabilityHandler = {
            let data = $0.availableData
            
            if data.isEmpty {
                return self.standardOutputPipe.fileHandleForReading.readabilityHandler = nil
            }
            
            self.standardOutputData.send(data)
        }
        
        process.standardError = standardErrorPipe
        
        standardErrorPipe.fileHandleForReading.readabilityHandler = {
            let data = $0.availableData
            
            if data.isEmpty {
                return self.standardErrorPipe.fileHandleForReading.readabilityHandler = nil
            }
            
            self.standardErrorData.send(data)
        }
    }
    
    private func teardownPipes() {
        standardOutputPipe.fileHandleForReading.readabilityHandler?(standardOutputPipe.fileHandleForReading)
        standardErrorPipe.fileHandleForReading.readabilityHandler?(standardErrorPipe.fileHandleForReading)
    }
}

// MARK: - API -

extension ProcessTask {
    public convenience init(
        executableURL: URL,
        arguments: [String],
        environment: [String: String]? = nil
    ) {
        let process = Process()
        
        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = environment
        
        self.init(process: process)
    }
    
    public convenience init(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil
    ) {
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.environment = environment
        
        self.init(process: process)
    }
}

extension ProcessTask {
    public var standardOutput: AnyPublisher<Data, Never> {
        standardOutputData.eraseToAnyPublisher()
    }
    
    public var standardError: AnyPublisher<Data, Never> {
        standardErrorData.eraseToAnyPublisher()
    }
}


#endif
