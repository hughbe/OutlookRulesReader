//
//  OnThisComputerOnlyCondition.swift
//  
//
//  Created by Hugh Bellamy on 07/08/2020.
//

import DataStream
import WindowsDataTypes

public struct OnThisComputerOnlyRuleElementData: RuleElementData {
    public let dataSize: UInt32 = 24

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var uuid: GUID
    
    public init(uuid: GUID) {
        self.uuid = uuid
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)

        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// UUID (16 bytes)
        self.uuid = try GUID(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)

        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// UUID (16 bytes)
        uuid.write(to: &dataStream)
    }
}
