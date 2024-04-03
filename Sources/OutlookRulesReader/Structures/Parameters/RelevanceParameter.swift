//
//  RelevanceParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RelevanceParameter: RuleParameter {
    public let dataSize: UInt32 = 8

    public var reserved: UInt32 = 0
    public var value: UInt32 = 1
    
    public init(value: UInt32) {
        self.value = value
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Value (4 bytes)
        self.value = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Value (4 bytes)
        dataStream.write(value, endianess: .littleEndian)
    }
}
