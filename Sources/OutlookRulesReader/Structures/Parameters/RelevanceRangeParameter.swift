//
//  RelevanceRangeParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct RelevanceRangeParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var minimum: UInt32
    public var maximum: UInt32

    public init(minimum: UInt32 = 0, maximum: UInt32) {
        self.minimum = minimum
        self.maximum = maximum
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Minimum Relevance (4 bytes)
        self.minimum = try dataStream.read(endianess: .littleEndian)
        
        /// Maximum Relevance (4 bytes)
        self.maximum = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Minimum Relevace (4 bytes)
        dataStream.write(minimum, endianess: .littleEndian)

        /// Maximum Relevance (4 bytes)
        dataStream.write(maximum, endianess: .littleEndian)
    }
}
