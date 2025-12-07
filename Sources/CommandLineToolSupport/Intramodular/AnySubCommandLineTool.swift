//
//  AnySubCommandLineTool.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/7.
//

import Diagnostics
import Foundation
import Merge
import Runtime

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class AnySubCommandLineTool<Parent: AnyCommandLineTool>: AnyCommandLineTool {
    final var parent: Parent?
    
    @available(*, unavailable, message: "Use `init(parent:)`")
    public override init() {
        fatalError(.unavailable)
    }
    
    public init(parent: Parent = .init()) {
        self.parent = parent
    }
    
    open override func makeCommand(operation: String? = nil) -> String {
        let subcommandInvocation = super.makeCommand(operation: operation) // command for this subcommand.
        guard let parent else { preconditionFailure("\"\(Self.self)\" does not attached to an instance of \"\(Parent.self)\".") }
        return [parent.makeCommand(operation: nil), subcommandInvocation].joined(separator: " ")
    }
}
