//
//  FlagRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct FlagRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 16
        baseSize += UTF16String(value: actionName).dataSize
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var days: UInt32
    public var actionName: String
    public var unknown: UInt32 = 0
    
    public init(action: String, days: UInt32) {
        self.actionName = action
        self.days = days
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Days (4 bytes)
        self.days = try dataStream.read(endianess: .littleEndian)

        /// Action Name (variable)
        if version >= .outlook2002 {
            self.actionName = try UTF16String(dataStream: &dataStream).value
        } else {
            self.actionName = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Unknown (4 bytes)
        self.unknown = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Days (4 bytes)
        dataStream.write(days, endianess: .littleEndian)
        
        /// Action Name (variable)
        UTF16String(value: actionName).write(to: &dataStream)
        
        /// Unknown (4 bytes)
        dataStream.write(unknown, endianess: .littleEndian)
    }
}
