//
//  ProfileStampParameter.swift
//  
//
//  Created by Hugh Bellamy on 07/08/2020.
//

import DataStream
import WindowsDataTypes

public struct ProfileStampParameter: RuleParameter {
    public let dataSize: UInt32 = 20

    public var reserved: UInt32 = 0
    public var uuid: GUID
    
    public init(uuid: GUID) {
        self.uuid = uuid
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// UUID (16 bytes)
        self.uuid = try GUID(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// UUID (16 bytes)
        uuid.write(to: &dataStream)
    }
}
