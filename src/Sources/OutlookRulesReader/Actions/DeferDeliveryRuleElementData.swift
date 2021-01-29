//
//  DeferDeliveryRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct DeferDeliveryRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var minutes: UInt32
    
    public init(minutes: UInt32) {
        self.minutes = minutes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Minutes (4 bytes)
        minutes = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

        // Minutes (4 bytes)
        dataStream.write(minutes, endianess: .littleEndian)
    }
}
