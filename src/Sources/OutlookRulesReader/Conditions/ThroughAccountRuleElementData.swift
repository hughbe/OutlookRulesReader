//
//  ThroughAccountCondition.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream

public struct ThroughAccountRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
        baseSize += UTF16String(value: accountName).dataSize
        baseSize += ASCIIString(value: accountName).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var accountName: String
    public var unknown3: String = "-190692068"
    
    public init(accountName: String) {
        self.accountName = accountName
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)

        // Account Name (variable)
        accountName = try UTF16String(dataStream: &dataStream).value
        
        // Unknown3 (variable)
        unknown3 = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Account Name (variable)
        UTF16String(value: accountName).write(to: &dataStream)

        // Unknown3 (variable)
        ASCIIString(value: accountName).write(to: &dataStream)
    }
}
