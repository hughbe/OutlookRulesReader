//
//  ASCIIString.swift
//
//
//  Created by Hugh Bellamy on 14/08/2020.
//

import DataStream
import Foundation

/// A length-prefixed string of 8-bit characters (String8 in spec §2.2).
internal struct ASCIIString {
    public var dataSize: UInt32 {
        let length = bytes.count
        return StringLength.size(of: length) + UInt32(length)
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
        /// Length (1, 3 or 7 bytes)
        let length = try StringLength.read(from: &dataStream)
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
        
        /// Length (1, 3 or 7 bytes)
        StringLength.write(bytes.count, to: &dataStream)
        
        /// Value (variable)
        dataStream.write(bytes)
    }
}
