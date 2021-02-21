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
    public static let afterServerReceived = ApplyConditionFlags(rawValue: 0x08)
}

public struct ApplyConditionRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 12

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public let flags: ApplyConditionFlags
    
    public init(flags: ApplyConditionFlags) {
        self.flags = flags
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Flags (4 bytes)
        self.flags = ApplyConditionFlags(rawValue: try dataStream.read(endianess: .littleEndian))
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Flags (4 bytes)
        dataStream.write(flags.rawValue, endianess: .littleEndian)
    }
}
