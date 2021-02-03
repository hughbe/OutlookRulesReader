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

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var days: UInt32
    public var actionName: String
    public var unknown3: UInt32 = 0
    
    public init(action: String, days: UInt32) {
        self.actionName = action
        self.days = days
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Days (4 bytes)
        self.days = try dataStream.read(endianess: .littleEndian)

        /// Action Name (variable)
        if !version.isASCII {
            self.actionName = try UTF16String(dataStream: &dataStream).value
        } else {
            self.actionName = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Days (4 bytes)
        dataStream.write(days, endianess: .littleEndian)
        
        /// Action Name (variable)
        UTF16String(value: actionName).write(to: &dataStream)
        
        /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
    }
}
