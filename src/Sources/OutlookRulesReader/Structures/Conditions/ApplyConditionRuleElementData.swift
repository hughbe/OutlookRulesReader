//
//  ApplyCondition.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct ApplyConditionFlags: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let afterReceived = ApplyConditionFlags(rawValue: 0x01)
    public static let afterSent = ApplyConditionFlags(rawValue: 0x04)
}

public struct ApplyConditionRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public let flags: ApplyConditionFlags
    
    public init(flags: ApplyConditionFlags) {
        self.flags = flags
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Flags (4 bytes)
        self.flags = ApplyConditionFlags(rawValue: try dataStream.read(endianess: .littleEndian))
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Flags (4 bytes)
        dataStream.write(flags.rawValue, endianess: .littleEndian)
    }
}
