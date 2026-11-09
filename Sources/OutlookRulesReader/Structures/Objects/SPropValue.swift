//
//  SPropValue.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import MAPI

/// A serialized MAPI `SPropValue` (spec §6.4): the property tag, `dwAlignPad` (`alignPad`, uninitialised memory)
/// and the 8-byte value union (`valueLow` and `valueHigh`).
internal struct SPropValue {
    public static var dataSize: UInt32 = 16
    
    public var tag: PropertyTag
    public var alignPad: UInt32
    public var valueLow: UInt32
    public var valueHigh: UInt32
    
    public init(dataStream: inout DataStream) throws {
        /// Tag (4 bytes)
        self.tag = try PropertyTag(dataStream: &dataStream)

        /// Align Pad (4 bytes)
        self.alignPad = try dataStream.read(endianess: .littleEndian)
        
        /// Value Low (4 bytes)
        self.valueLow = try dataStream.read(endianess: .littleEndian)
        
        /// Value High (4 bytes)
        self.valueHigh = try dataStream.read(endianess: .littleEndian)
    }
}
