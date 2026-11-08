//
//  DeferParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct DeferParameter: RuleParameter {
    public let dataSize: UInt32 = 8

    public var reserved: UInt32 = 0
    public var minutes: UInt32
    
    public init(minutes: UInt32) {
        self.minutes = minutes
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Minutes (4 bytes)
        self.minutes = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Minutes (4 bytes)
        dataStream.write(minutes, endianess: .littleEndian)
    }
}
