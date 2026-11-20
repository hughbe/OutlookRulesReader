//
//  ASCIIString.swift
//
//
//  Created by Hugh Bellamy on 14/08/2020.
//

import DataStream
import Foundation

/// A length-prefixed string of 8-bit characters in the ANSI code page (String8 in spec §2.2). See `ANSIEncoding`.
internal struct ASCIIString {
    public var dataSize: UInt32 {
        let length = bytes.count
        return StringLength.size(of: length) + UInt32(length)
    }
    
    public var value: String
    
    /// The bytes of the value. Characters that the ANSI code page can't represent are written as "?".
    private var bytes: [UInt8] {
        ANSIEncoding.encode(value)
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
        self.value = ANSIEncoding.decode(try dataStream.readBytes(count: length))
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        let bytes = self.bytes
        
        /// Length (1, 3 or 7 bytes)
        StringLength.write(bytes.count, to: &dataStream)
        
        /// Value (variable)
        dataStream.write(bytes)
    }
}
