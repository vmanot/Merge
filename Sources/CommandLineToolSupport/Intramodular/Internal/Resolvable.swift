//
//  Resolvable.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/8.
//

import Foundation

public protocol Resolvable {
    associatedtype Result
    associatedtype Context = Void
    func resolve(in context: Context) throws -> Result
}
