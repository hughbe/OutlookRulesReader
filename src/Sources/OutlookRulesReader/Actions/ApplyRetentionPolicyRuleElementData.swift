//
//  ApplyRetentionPolicyRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import WindowsDataTypes

public struct ApplyRetentionPolicyRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 24 + UTF16String(value: name).dataSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var guid: GUID
    public var name: String

    public init(guid: GUID, name: String) {
        self.guid = guid
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Guid (16 bytes)
        self.guid = try GUID(dataStream: &dataStream)
        
        /// Name (variable)
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Guid (16 bytes)
        guid.write(to: &dataStream)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
