//
//  UTF16String.swift
//  
//
//  Created by Hugh Bellamy on 14/08/2020.
//

import DataStream

/// A length-prefixed UTF-16 little-endian string (StringW in spec §2.2).
/// The length is measured in UTF-16 code units.
internal struct UTF16String {
    public var dataSize: UInt32 {
        let length = value.utf16.count
        return StringLength.size(of: length) + UInt32(length) * 2
    }
    
    public var value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init(dataStream: inout DataStream) throws {
        /// Length (1, 3 or 7 bytes)
        let length = try StringLength.read(from: &dataStream)
        guard length <= dataStream.remainingCount / 2 else {
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
        /// Length (1, 3 or 7 bytes)
        StringLength.write(value.utf16.count, to: &dataStream)
        
        /// Value (variable)
        dataStream.write(value, encoding: .utf16LittleEndian)
    }
}
