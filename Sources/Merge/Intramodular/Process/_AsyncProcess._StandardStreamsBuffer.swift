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
        
        await forwardToTerminalIfNecessary(data: data, forPipe: pipeName)
    }
    
    private func forwardToTerminalIfNecessary(
        data: Data,
        forPipe pipe: _ProcessPipeName
    ) async {
        let forwardStdoutStderrToTerminal: Bool = options.contains(where: { $0._stdoutStderrSink == .terminal }) // FIXME: (@vmanot) unhandled cases
        
        if forwardStdoutStderrToTerminal {
            switch pipe {
                case .standardOutput:
                    FileHandle.standardOutput.write(data)
                case .standardError:
                    FileHandle.standardError.write(data)
                default:
                    break
            }
        }
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
