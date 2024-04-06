import Foundation

extension Data {
    
    public func asJSON<D: Decodable>(
        decoding type: D.Type,
        using jsonDecoder: JSONDecoder = .init()
    ) throws -> D {
        try jsonDecoder.decode(type, from: self)
    }
}

extension Data {
    
    public func asTrimmedString(encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
