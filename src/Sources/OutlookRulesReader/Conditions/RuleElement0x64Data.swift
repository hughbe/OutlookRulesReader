//
//  RuleElement0x64Condition.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RuleElement0x64Data: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var unknown3: UInt32 = 1
    
    public init() {
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
    }
}
