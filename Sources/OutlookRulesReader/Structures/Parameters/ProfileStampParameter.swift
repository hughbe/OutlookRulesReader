//
//  ProfileStampParameter.swift
//  
//
//  Created by Hugh Bellamy on 07/08/2020.
//

import DataStream
import WindowsDataTypes

public struct ProfileStampParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var stamp: GUID
    
    public init(stamp: GUID) {
        self.stamp = stamp
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// UUID (16 bytes)
        self.stamp = try GUID(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// UUID (16 bytes)
        stamp.write(to: &dataStream)
    }
}
