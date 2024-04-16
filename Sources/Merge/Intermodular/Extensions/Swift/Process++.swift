//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Dispatch
import Foundation
import Swift

extension Process {
    public convenience init(
        command: String,
        environment: [String: String] = [:],
        currentDirectoryPath: String? = nil
    ) {
        self.init()
        
        self.executableURL = URL(fileURLWithPath: "/bin/zsh")
        self.arguments = ["-l", "-c", command]
        self.environment = ProcessInfo.processInfo.environment.merging(environment) { lhs, rhs in
            rhs
        }
        
        if let currentDirectoryPath = currentDirectoryPath {
            self.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        }
    }
}

extension Process {
    func pipeStandardOutput<S: Subject>(
        on queue: DispatchQueue,
        to sink: S
    ) -> DispatchSourceRead where S.Output == String {
        let pipe = Pipe()
        
        standardOutput = pipe
        
        let source = DispatchSource.makeReadTextSource(pipe: pipe, queue: queue, sink: sink, encoding: .utf8)
        
        source.activate()
        
        return source
    }
    
    func pipeStandardError<S: Subject>(
        on queue: DispatchQueue,
        to sink: S
    ) -> DispatchSourceRead where S.Output == String {
        let pipe = Pipe()
        
        standardError = pipe
        
        let source = DispatchSource.makeReadTextSource(pipe: pipe, queue: queue, sink: sink, encoding: .utf8)
        
        source.activate()
        
        return source
    }
}

#endif
