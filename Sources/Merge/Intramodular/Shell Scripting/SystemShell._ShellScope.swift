//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    package struct _ShellScope: Identifiable, Hashable, Sendable {
        package struct ID: Hashable, Sendable {
            package let rawValue: UUID

            package init() {
                self.rawValue = UUID()
            }

            package init(rawValue: UUID) {
                self.rawValue = rawValue
            }
        }

        package enum Kind: Hashable, Sendable {
            case commandLineToolLease
            case configurationScope
        }

        package enum Status: Hashable, Sendable {
            case active
            case completed
        }

        package let id: ID
        package let parentID: ID?
        package let rootID: ID
        package let kind: Kind
        package var status: Status

        package init(
            id: ID = ID(),
            kind: Kind,
            status: Status = .active
        ) {
            self.id = id
            self.parentID = nil
            self.rootID = id
            self.kind = kind
            self.status = status
        }

        package init(
            id: ID = ID(),
            parentID: ID,
            rootID: ID,
            kind: Kind,
            status: Status = .active
        ) {
            self.id = id
            self.parentID = parentID
            self.rootID = rootID
            self.kind = kind
            self.status = status
        }
    }
}
