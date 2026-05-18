#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public enum _DeveloperError: Swift.Error, Hashable, CustomStringConvertible {
        case killedInstanceUsage
        case failedToKillShellSessions(failedSessionCount: Int, totalSessionCount: Int)

        public var description: String {
            switch self {
                case .killedInstanceUsage:
                    return "Cannot use an AnyCommandLineTool instance after kill() has been called on it."
                case .failedToKillShellSessions(let failedSessionCount, let totalSessionCount):
                    return "Failed to kill running command-line tool work: \(failedSessionCount) of \(totalSessionCount) tracked shell session(s) remained incomplete after teardown."
            }
        }
    }
}
#endif
