//
//  DeferDeliveryRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct DeferDeliveryRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var minutes: UInt32
    
    public init(minutes: UInt32) {
        self.minutes = minutes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Minutes (4 bytes)
        self.minutes = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Minutes (4 bytes)
        dataStream.write(minutes, endianess: .littleEndian)
    }
}
