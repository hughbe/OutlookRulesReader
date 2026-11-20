//
//  ANSIEncoding.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

/// The 8-bit "ANSI" strings of the Outlook 97–2000 formats (String8 in spec §2.2) are in the writer's ANSI code page.
/// That is assumed to be Windows-1252, the code page of Western-language Windows.
///
/// Every byte decodes to a character and back to the same byte, so strings round-trip unchanged. The five bytes that
/// Windows-1252 leaves undefined (0x81, 0x8D, 0x8F, 0x90 and 0x9D) decode to the C1 control with the same value, as
/// Windows' `MultiByteToWideChar` does. Characters that Windows-1252 can't represent are written as "?", as Windows'
/// `WideCharToMultiByte` does.
///
/// This is implemented with a table instead of `String.Encoding`, because how Foundation decodes bytes 0x80 and above
/// with `.ascii` depends on the platform and the deployment target (macOS 12 decodes them as Latin-1; macOS 26 fails).
internal enum ANSIEncoding {
    /// The characters of bytes 0x80–0x9F. The other bytes are the Unicode scalar with the same value.
    private static let highTable: [UInt32] = [
        0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
        0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
        0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
        0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
    ]

    private static let reverseTable: [UInt32: UInt8] = {
        var table: [UInt32: UInt8] = [:]
        for (index, scalar) in highTable.enumerated() {
            table[scalar] = UInt8(0x80 + index)
        }
        return table
    }()

    static func decode<Bytes: Sequence>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
        var scalars = String.UnicodeScalarView()
        for byte in bytes {
            let value = byte >= 0x80 && byte <= 0x9F ? highTable[Int(byte - 0x80)] : UInt32(byte)
            scalars.append(Unicode.Scalar(value)!)
        }

        return String(scalars)
    }

    static func encode(_ string: String) -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(string.unicodeScalars.count)
        for scalar in string.unicodeScalars {
            let value = scalar.value
            if let byte = reverseTable[value] {
                bytes.append(byte)
            } else if value < 0x80 || (value >= 0xA0 && value <= 0xFF) {
                bytes.append(UInt8(value))
            } else {
                bytes.append(0x3F) // "?"
            }
        }

        return bytes
    }
}
