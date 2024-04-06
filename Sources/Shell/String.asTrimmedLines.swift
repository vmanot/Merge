//
// Copyright (c) Vatsal Manot
//

import Foundation

extension String {
    public func asTrimmedLines() -> [String] {
        self
            .split(separator: "\n")
            .map { slice in
                String(slice)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
    }
}
