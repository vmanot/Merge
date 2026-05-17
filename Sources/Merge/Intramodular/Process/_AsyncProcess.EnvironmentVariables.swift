//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public struct EnvironmentVariables: Hashable, Sendable {
        package enum Policy: Hashable, Sendable {
            case inherit
            case inheritOverriding([String: String])
            case exact([String: String])
            case empty
        }

        package var policy: Policy

        package init(
            policy: Policy
        ) {
            self.policy = policy
        }

        public init(
            dictionaryLiteral elements: (String, String)...
        ) {
            self = .inherited(
                overriding: Dictionary(
                    elements,
                    uniquingKeysWith: { _, rhs in rhs }
                )
            )
        }

        public static var inherited: Self {
            Self(policy: .inherit)
        }

        public static func inherited(
            overriding variables: [String: String]
        ) -> Self {
            if variables.isEmpty {
                return .inherited
            }

            return Self(policy: .inheritOverriding(variables))
        }

        public static func exact(
            _ variables: [String: String]
        ) -> Self {
            variables.isEmpty ? .empty : Self(policy: .exact(variables))
        }

        public static var empty: Self {
            Self(policy: .empty)
        }

        public func resolvingForProcessLaunch() -> [String: String]? {
            switch policy {
                case .inherit:
                    return nil
                case .inheritOverriding(let variables):
                    return ProcessInfo.processInfo.environment.merging(
                        variables,
                        uniquingKeysWith: { _, rhs in rhs }
                    )
                case .exact(let variables):
                    return variables
                case .empty:
                    return [:]
            }
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess.EnvironmentVariables: ExpressibleByDictionaryLiteral {

}
