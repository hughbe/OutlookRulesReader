//
//  UTF16String.swift
//  
//
//  Created by Hugh Bellamy on 14/08/2020.
//

import DataStream

internal struct UTF16String {
    public var dataSize: UInt32 {
        let length = value.utf16.count
        return (length >= 0xFF ? 3 : 1) + UInt32(length) * 2
    }
    
    public var value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init(dataStream: inout DataStream) throws {
        /// Length (1 byte or 3 bytes if first byte is 0xFF)
        var length: Int
        let byteLength = try dataStream.read() as UInt8
        if byteLength < 0xFF {
            length = Int(byteLength)
        } else {
            length = Int(try dataStream.read(endianess: .littleEndian) as UInt16)
        }

        guard length <= Int.max / 2 && length <= dataStream.remainingCount else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Value (variable)
        guard let value = try dataStream.readString(count: length * 2, encoding: .utf16LittleEndian) else {
            throw OutlookRulesReadError.corrupted
        }
        
        self.value = value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// The length is measured in UTF-16 code units, not in Characters (e.g. "\r\n" is one Character
        /// but two code units).
        let length = value.utf16.count
        
        /// Length (1 byte or 3 bytes if length >= 255)
        if length < 0xFF {
            dataStream.write(UInt8(length))
        } else {
            dataStream.write(0xFF as UInt8)
            dataStream.write(UInt16(length), endianess: .littleEndian)
        }
        
        /// Value (variable)
        dataStream.write(value, encoding: .utf16LittleEndian)
    }
}
