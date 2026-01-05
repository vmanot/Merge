//
//  CommandLineToolSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public protocol InvocationSummary {
    associatedtype Command: AnyCommandLineTool
    func invocationArguments(for command: Command) throws -> [String]
}
