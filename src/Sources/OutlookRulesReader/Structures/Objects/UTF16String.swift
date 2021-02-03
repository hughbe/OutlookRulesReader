//
//  UTF16String.swift
//  
//
//  Created by Hugh Bellamy on 14/08/2020.
//

import DataStream

internal struct UTF16String {
    public var dataSize: UInt32 {
        return (value.count >= 256 ? 3 : 1) + UInt32(value.count) * 2
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
        /// Length (1 byte or 3 bytes if length >= 256)
        if value.count < 0xFF {
            dataStream.write(UInt8(value.count))
        } else {
            dataStream.write(0xFF as UInt8)
            dataStream.write(UInt16(value.count), endianess: .littleEndian)
        }
        
        /// Value (variable)
        dataStream.write(value, encoding: .utf16LittleEndian)
    }
}
