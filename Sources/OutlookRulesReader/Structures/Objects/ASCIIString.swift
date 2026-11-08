//
//  ASCIIString.swift
//
//
//  Created by Hugh Bellamy on 14/08/2020.
//

import DataStream
import Foundation

internal struct ASCIIString {
    public var dataSize: UInt32 {
        let length = bytes.count
        return (length >= 0xFF ? 3 : 1) + UInt32(length)
    }
    
    public var value: String
    
    /// The bytes of the value. Reading decodes each byte to the matching Latin-1 scalar, so write the inverse;
    /// characters that cannot be represented are converted lossily.
    private var bytes: Data {
        value.data(using: .isoLatin1, allowLossyConversion: true) ?? Data()
    }
    
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

        guard length <= dataStream.remainingCount else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Value (variable)
        guard let value = try dataStream.readString(count: length, encoding: .ascii) else {
            throw OutlookRulesReadError.corrupted
        }
        
        self.value = value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        let bytes = self.bytes
        
        /// Length (1 byte or 3 bytes if length >= 255)
        if bytes.count < 0xFF {
            dataStream.write(UInt8(bytes.count))
        } else {
            dataStream.write(0xFF as UInt8)
            dataStream.write(UInt16(bytes.count), endianess: .littleEndian)
        }
        
        /// Value (variable)
        dataStream.write(bytes)
    }
}
