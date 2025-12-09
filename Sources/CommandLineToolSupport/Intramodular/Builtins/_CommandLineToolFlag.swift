//
//  _CommandLineToolFlag.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/9.
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Flag<T: Equatable> = _CommandLineToolFlag<T>
}

public protocol _CommandLineToolFlagProtocol: PropertyWrapper where WrappedValue : Equatable {
    /// The name of the parameter as it will be passed in the actual command being invoked.
    var key: _CommandLineToolOptionKey { get }
    
    var inversion: _CommandLineToolFlagInversion? { get }
    
    var defaultValue: WrappedValue { get }
}

@propertyWrapper
public struct _CommandLineToolFlag<WrappedValue: Equatable>: _CommandLineToolFlagProtocol {
    var _wrappedValue: WrappedValue
    
    public var key: _CommandLineToolOptionKey
    public var inversion: _CommandLineToolFlagInversion?
    public var defaultValue: WrappedValue
  
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }

    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKey,
        inversion: _CommandLineToolFlagInversion? = nil
    ) where WrappedValue == Bool {
        self._wrappedValue = wrappedValue
        self.defaultValue = wrappedValue
        self.key = key
        self.inversion = inversion
    }
    
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKey
    ) where WrappedValue == Int {
        self._wrappedValue = wrappedValue
        self.defaultValue = wrappedValue
        self.key = key
    }
    
    @available(*, deprecated, message: "This flag will be ignored. Make sure `WrappedValue` conforms to `CLT.ArgumentValueConvertible`.")
    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKey,
        inversion: _CommandLineToolFlagInversion? = nil
    ) {
        self._wrappedValue = wrappedValue
        self.defaultValue = wrappedValue
        self.key = key
        self.inversion = inversion
    }
}

public enum _CommandLineToolFlagInversion: Hashable, Sendable {
    /// Emit `--no-<name>` when the value is `false`.
    case prefixedNo
    /// Emit `--enable-<name>` when `true` and `--disable-<name>` when `false`.
    case prefixedEnableDisable
    
    func insertionText(flagValue: Bool) -> String? {
        switch self {
            case .prefixedNo:
                flagValue == false ? "no" : nil
            case .prefixedEnableDisable:
                flagValue ? "enable" : "disable"
        }
    }
}
