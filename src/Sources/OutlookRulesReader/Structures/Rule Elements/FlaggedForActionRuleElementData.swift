//
//  FlaggedForActionCondition.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct FlaggedForActionRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 12
        baseSize += UTF16String(value: action).dataSize
        baseSize += 4
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var unknown1: UInt32 = 0
    public var action: String
    public var unknown2: UInt32 = 1
    
    public init(action: String) {
        self.action = action
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
    
        /// Action (variable)
        if version >= .outlook2002 {
            self.action = try UTF16String(dataStream: &dataStream).value
        } else {
            self.action = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Action (variable)
        UTF16String(value: action).write(to: &dataStream)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
    }
}
