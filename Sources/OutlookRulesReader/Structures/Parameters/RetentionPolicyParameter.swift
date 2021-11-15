//
//  RetentionPolicyParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import WindowsDataTypes

public struct RetentionPolicyParameter: RuleParameter {
    public var dataSize: UInt32 {
        return 20 + UTF16String(value: name).dataSize
    }

    public var reserved: UInt32 = 0
    public var guid: GUID
    public var name: String

    public init(guid: GUID, name: String) {
        self.guid = guid
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Guid (16 bytes)
        self.guid = try GUID(dataStream: &dataStream)
        
        /// Name (variable)
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Guid (16 bytes)
        guid.write(to: &dataStream)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
