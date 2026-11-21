//
//  UTF16Decoding.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

internal enum UTF16Decoding {
    /// Decodes little-endian UTF-16 bytes. Throws `invalidString` for an unpaired surrogate, rather than replacing it
    /// as Foundation may, so that a string is never silently changed when it is written back.
    static func decode(_ bytes: [UInt8]) throws -> String {
        let units = stride(from: 0, to: bytes.count - 1, by: 2).map { UInt16(bytes[$0]) | UInt16(bytes[$0 + 1]) << 8 }
        var scalars = String.UnicodeScalarView()
        var iterator = units.makeIterator()
        var decoder = UTF16()
        while true {
            switch decoder.decode(&iterator) {
            case .scalarValue(let scalar):
                scalars.append(scalar)
            case .emptyInput:
                return String(scalars)
            case .error:
                throw OutlookRulesReadError.invalidString
            }
        }
    }
}
