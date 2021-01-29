//
//  FlaggedForActionCondition.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct FlaggedForActionRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 8 // TODO

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var unknown3: UInt32 = 0
    public var action: String
    public var unknown4: UInt32 = 1
    
    public init(action: String) {
        self.action = action
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
    
        // Action (variable)
        action = try UTF16String(dataStream: &dataStream).value
        
        // Unknown4 (4 bytes)
        unknown4 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        
        // Action (variable)
        UTF16String(value: action).write(to: &dataStream)
        
        // Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)
    }
}
