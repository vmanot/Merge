//
//  InvocationSummaryValue.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public struct InvocationSummaryValue<Value> {
    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }
}

extension InvocationSummaryValue {
    public func argumentTokens() -> [String] {
        guard let unwrapped = _unwrapOptional(value) else {
            return []
        }

        if let array = unwrapped as? [any CLT.ArgumentValueConvertible] {
            return array
                .map(\.argumentValue)
                .filter { !$0.isEmpty }
        }

        if let convertible = unwrapped as? CLT.ArgumentValueConvertible {
            let argument = convertible.argumentValue
            return argument.isEmpty ? [] : [argument]
        }

        return [String(describing: unwrapped)]
    }
}

// MARK: - Auxiliary

fileprivate func _unwrapOptional(_ value: Any) -> Any? {
    if let optional = value as? any OptionalProtocol, optional.isNil {
        return nil
    }

    let mirror = Mirror(reflecting: value)

    if mirror.displayStyle == .optional {
        return mirror.children.first?.value
    }

    return value
}
