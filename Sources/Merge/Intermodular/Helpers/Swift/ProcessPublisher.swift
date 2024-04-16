//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Combine

public enum ProcessExitFailure: Error, Hashable {
    /// The process exited with a non-zero exit status.
    case exit(status: CInt)
    /// The process had an abnormal exit, such as an uncaught signal.
    /// Also used for future additions to Process.TerminationReason.
    case abort(Process.TerminationReason)
    
    /// The process exited with an uncaught signal.
    public static var uncaughtSignal: Self {
        .abort(.uncaughtSignal)
    }
}

// Marker protocol for safer working with Process's standardInput/Output/Error.
#if canImport(ObjectiveC)
@objc internal protocol PipeOrFileHandle: AnyObject {}
#else
internal protocol PipeOrFileHandle: AnyObject {}
#endif
extension Pipe: PipeOrFileHandle {}
extension FileHandle: PipeOrFileHandle {}

/// A publisher that runs a process (using Foundation.Process) and streams its
/// standard output as Data chunks.
///
/// The failure kind is ProcessExitFailure by default, but ProcessPublisher can
/// also be composed with a publisher that produces generic Error failures.
/// Errors from an input publisher will be forwarded on and the running process
/// will be terminated.
///
/// By default a ProcessPublisher does not take any input, but if created using
/// an operator such as `pipe`, it will accept standard input in the form of
/// Data chunks from an upstream publisher.
///
/// The process will not be launched until it is connected; it also will not
/// subscribe to the upstream input publisher until this publisher is connected.
/// Cancelling the publisher will terminate the running process.
///
/// Output is not buffered, so you should explicitly buffer if subscribers do
/// not have unlimited demand. To receive all of a process's output as a single
/// Data value, use `.reduce(Data(), +)`.
///
/// Note that despite being a struct, this publisher has reference semantics:
/// copying it will share the process and the subscribers.
public struct ProcessPublisher<Failure: Error>: ConnectablePublisher {
    public typealias Output = Data
    
    fileprivate var process: Process
    fileprivate var inputPublisher: AnyPublisher<Data, Failure>?
    fileprivate var directInput: PipeOrFileHandle?
    fileprivate var output: PassthroughSubject<Data, Failure> = .init()
    
    /// "Designated initializer" for ProcessPublisher.
    ///
    /// This initializer isn't public API, but the arguments are a little tricky.
    ///
    /// - parameter command: The executable to run
    /// - parameter arguments: The arguments to pass to the executable.
    ///     May be empty.
    /// - parameter input: The upstream publisher to subscribe to for input,
    ///     if any.
    /// - parameter directInput: A replacement for stdin in the created process.
    ///     Either `input` or `directInput` must be provided; if both are present,
    ///     failures are passed through from `input`, but the values produced by
    ///     `input` are ignored.
    /// - parameter errorHandler: Allows certain kinds of exit to be processed
    ///     before being converted to the publisher's failure type (Error or
    ///     ProcessExitFailure).
    internal init(
        _ command: URL,
        arguments: [String],
        input: AnyPublisher<Data, Failure>?,
        directInput: PipeOrFileHandle? = nil,
        errorHandler: @escaping (ProcessExitFailure) -> Failure
    ) {
        assert(input != nil || directInput != nil)
        assert(Failure.self == Error.self || Failure.self == ProcessExitFailure.self)
        
        self.process = Process()
        self.process.executableURL = command
        self.process.arguments = arguments
        
        // Delay setting up the input until connect() is called.
        self.inputPublisher = input
        self.directInput = directInput
        
        // Conversely, the output is set up now to make directPipe() simpler.
        let outputPipe = Pipe()
        
        process.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { [output] in
            let data = $0.availableData
            if data.isEmpty {
                outputPipe.fileHandleForReading.readabilityHandler = nil
                return
            }
            output.send(data)
        }
        
        process.terminationHandler = { [output] process in
            // Force any last output.
            outputPipe.fileHandleForReading.readabilityHandler?(outputPipe.fileHandleForReading)
            
            switch process.terminationReason {
                case .exit:
                    let status = process.terminationStatus
                    if status == 0 {
                        output.send(completion: .finished)
                    } else {
                        output.send(completion: .failure(errorHandler(.exit(status: status))))
                    }
                case .uncaughtSignal:
                    fallthrough
                @unknown default:
                    output.send(completion: .failure(errorHandler(.abort(process.terminationReason))))
            }
        }
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, S.Input == Data, S.Failure == Failure {
        output.receive(subscriber: subscriber)
    }
    
    /// Subscribes to any upstream publisher and launches the process.
    ///
    /// Cancelling the publisher will terminate the process, as well as cancelling
    /// the upstream subscription.
    public func connect() -> Cancellable {
        let manualStdin: FileHandle?
        if let directInput = self.directInput {
            process.standardInput = directInput
            manualStdin = nil
        } else {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            manualStdin = stdinPipe.fileHandleForWriting
        }
        
        self.process.launch()
        
        let subscription = self.inputPublisher?.sink(receiveCompletion: { [manualStdin] result in
            try! manualStdin?.close() // This one can't fail; we opened the pipe.
            if case .failure(let error) = result {
                self.process.terminationHandler = nil
                self.process.terminate()
                self.output.send(completion: .failure(error))
            }
        }, receiveValue: { [manualStdin] data in
            manualStdin?.write(data)
        })
        
        return AnyCancellable {
            self.process.terminate()
            subscription?.cancel()
        }
    }
    
    /// Runs the PID of the process.
    ///
    /// Can only be called once the process has launched, i.e. once the publisher
    /// has been connected.
    public var processIdentifier: pid_t {
        let result = self.process.processIdentifier
        precondition(result != 0, "process not launched yet; use connect() to start")
        return result
    }
    
    /// Accesses the QoS of the process.
    ///
    /// This must be set *before* the process has launched.
    ///
    /// - SeeAlso: `Process.qualityOfService`
    /// - SeeAlso: `ProcessPublisher.assignQualityOfService(_:)`
    public var qualityOfService: QualityOfService {
        get { self.process.qualityOfService }
        nonmutating set { self.process.qualityOfService = newValue }
    }
    
    /*testable*/internal var isRunning: Bool {
        return self.process.isRunning
    }
}

/// Describes where to read from for a ProcessPublisher not created by an
/// operator.
public enum ProcessStdinSource {
    /// No stdin. This is the default.
    ///
    /// This is roughly equivalent to using an `Empty<Data, ProcessExitFailure>`
    /// as the input publisher, but should be slightly more efficient.
    case nullDevice
    
    /// Read from this process's standard input.
    case standardInput
    
    fileprivate var correspondingFileHandle: FileHandle {
        switch self {
            case .nullDevice: return .nullDevice
            case .standardInput: return .standardInput
        }
    }
}

extension ProcessPublisher where Failure == ProcessExitFailure {
    /// Create a process using the first argument as the command to run.
    ///
    /// The command will be found in `$PATH` as if run through `env`. It is a
    /// fatal error if the command cannot be found; if you want to handle this
    /// case, invoke `env` explicitly and handle the failure.
    public init(_ arguments: [String], readingFrom source: ProcessStdinSource = .nullDevice) {
        validateArgumentsForEnv(arguments)
        self.init(envExecutableURL, arguments: arguments, input: nil, directInput: source.correspondingFileHandle, errorHandler: makeErrorCheckerForEnv(arguments) { $0 })
    }
    
    /// Create a process to run the given command, which must refer to an
    /// executable the user has permission to run.
    public init(_ command: URL, arguments: [String] = [], readingFrom source: ProcessStdinSource = .nullDevice) {
        self.init(command, arguments: arguments, input: nil, directInput: source.correspondingFileHandle, errorHandler: { $0 })
    }
}

extension ProcessPublisher {
    /// Sets the QoS class of the process to `qos`.
    ///
    /// This is provided as a convenience for building pipelines in Combine.
    /// It does *not* mean that different pipelines can use different QoS classes
    /// for the same process.
    ///
    /// - SeeAlso: `Process.qualityOfService`
    /// - SeeAlso: `ProcessPublisher.qualityOfService`
    public func assignQualityOfService(
        _ qos: QualityOfService
    ) -> Self {
        self.qualityOfService = qos
        return self
    }
    
    /// Returns the pipe used for standard output, after checking that no one else
    /// is using it for anything.
    internal func prepareForDirectPipe() -> Pipe {
        let pipe = self.process.standardOutput! as! Pipe
        precondition(pipe.fileHandleForReading.readabilityHandler != nil, "already direct-piped to something else")
        pipe.fileHandleForReading.readabilityHandler = nil
        return pipe
    }
}

#endif
