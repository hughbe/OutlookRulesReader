//
//  PropertyValueHeader.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import MAPI

internal struct PropertyValueHeader {
    public static var dataSize: UInt32 = 16
    
    public var tag: PropertyTag
    public var data1: UInt32
    public var data2: UInt32
    public var data3: UInt32
    
    public init(dataStream: inout DataStream) throws {
        /// Tag (4 bytes)
        self.tag = try PropertyTag(dataStream: &dataStream)

        /// Data 1 (4 bytes)
        self.data1 = try dataStream.read(endianess: .littleEndian)
        
        /// Data 2 (4 bytes)
        self.data2 = try dataStream.read(endianess: .littleEndian)
        
        /// Data 3 (4 bytes)
        self.data3 = try dataStream.read(endianess: .littleEndian)
    }
}
