//
//  SPropValue.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import MAPI

/// A serialized MAPI `SPropValue` (spec §6.4): the property propTag, `dwAlignPad` (`alignPad`, uninitialised memory)
/// and the 8-byte value union (`valueLow` and `valueHigh`).
internal struct SPropValue {
    static let dataSize: UInt32 = 16
    
    var propTag: PropertyTag
    var alignPad: UInt32
    var valueLow: UInt32
    var valueHigh: UInt32
    
    init(dataStream: inout DataStream) throws {
        /// Tag (4 bytes)
        self.propTag = try PropertyTag(dataStream: &dataStream)

        /// Align Pad (4 bytes)
        self.alignPad = try dataStream.read(endianess: .littleEndian)
        
        /// Value Low (4 bytes)
        self.valueLow = try dataStream.read(endianess: .littleEndian)
        
        /// Value High (4 bytes)
        self.valueHigh = try dataStream.read(endianess: .littleEndian)
    }
}
