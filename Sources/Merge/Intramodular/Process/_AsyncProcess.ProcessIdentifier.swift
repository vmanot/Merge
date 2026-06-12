//
// Copyright (c) Vatsal Manot
//

#if canImport(Darwin)
import Darwin

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    /// A platform-independent identifier for a subprocess.
    public struct ProcessIdentifier: Sendable, Hashable {
        /// The platform-specific process identifier value.
        public let value: pid_t

        /// Creates a process identifier with the given value.
        public init(value: pid_t) {
            self.value = value
        }

        internal func close() { /* No-op on Darwin */  }
    }

    /// The process identifier of this subprocess.
    public var processIdentifier: ProcessIdentifier {
        #if os(macOS)
        ProcessIdentifier(value: process.processIdentifier)
        #else
        fatalError(.unavailable)
        #endif
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess.ProcessIdentifier: CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of the process identifier.
    public var description: String { "\(self.value)" }
    /// A debug-oriented textual representation of the process identifier.
    public var debugDescription: String { "\(self.value)" }
}

#endif // canImport(Darwin)
