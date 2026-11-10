//
//  StringLength.swift
//
//
//  Created by Hugh Bellamy on 08/11/2026.
//

import DataStream

/// The length prefix of a length-prefixed string. This is the encoding MFC's `CArchive` uses for `CString`:
/// one byte if the length is less than 0xFF, otherwise 0xFF followed by two bytes if the length is less than 0xFFFF,
/// otherwise 0xFF 0xFFFF followed by four bytes. See spec §2.2.
internal enum StringLength {
    static func read(from dataStream: inout DataStream) throws -> Int {
        /// Length (1 byte)
        let length8: UInt8 = try dataStream.read()
        if length8 < 0xFF {
            return Int(length8)
        }

        /// Length16 (2 bytes)
        let length16: UInt16 = try dataStream.read(endianess: .littleEndian)
        if length16 < 0xFFFF {
            return Int(length16)
        }

        /// Length32 (4 bytes)
        let length32: UInt32 = try dataStream.read(endianess: .littleEndian)
        return Int(length32)
    }

    static func write(_ length: Int, to dataStream: inout OutputDataStream) {
        if length < 0xFF {
            dataStream.write(UInt8(length))
        } else if length < 0xFFFF {
            dataStream.write(0xFF as UInt8)
            dataStream.write(UInt16(length), endianess: .littleEndian)
        } else {
            dataStream.write(0xFF as UInt8)
            dataStream.write(0xFFFF as UInt16, endianess: .littleEndian)
            dataStream.write(UInt32(length), endianess: .littleEndian)
        }
    }

    static func size(of length: Int) -> UInt32 {
        if length < 0xFF {
            return 1
        } else if length < 0xFFFF {
            return 3
        } else {
            return 7
        }
    }
}

/// A string whose encoding depends on the format: UTF-16 from Outlook 2002 on, ANSI before (spec §2.2 "String").
internal enum VersionedString {
    static func read(from dataStream: inout DataStream, version: OutlookRulesVersion) throws -> String {
        if version >= .outlook2002 {
            return try UTF16String(dataStream: &dataStream).value
        } else {
            return try ASCIIString(dataStream: &dataStream).value
        }
    }

    static func write(_ value: String, to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        if version >= .outlook2002 {
            UTF16String(value: value).write(to: &dataStream)
        } else {
            ASCIIString(value: value).write(to: &dataStream)
        }
    }
}
