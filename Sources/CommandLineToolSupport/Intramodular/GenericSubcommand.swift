//
//  GenericSubcommand.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow

public protocol CommandLineToolOptionGroup {

}

public struct EmptyCommandLineToolOptionGroup: CommandLineToolOptionGroup {
    public init() { }
}

public struct GenericSubcommand<Parent, AdditionalArguments, Result> where AdditionalArguments: CommandLineToolOptionGroup {
    public var optionGroup: AdditionalArguments
    
    public init(
        optionGroup: AdditionalArguments
    ) {
        self.optionGroup = optionGroup
    }
    
    @discardableResult
    public func callAsFunction(on parent: Parent) async throws -> Result {
        fatalError(.unimplemented)
    }
    
    public func with<T>(
        _ keyPath: WritableKeyPath<AdditionalArguments, T>,
        _ newValue: T
    ) -> Self {
        var copy = self
        copy.optionGroup[keyPath: keyPath] = newValue
        return copy
    }
}
