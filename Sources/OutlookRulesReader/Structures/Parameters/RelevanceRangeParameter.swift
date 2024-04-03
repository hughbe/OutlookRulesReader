//
//  RelevanceRangeParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct RelevanceRangeParameter: RuleParameter {
    public let dataSize: UInt32 = 12

    public var reserved: UInt32 = 0
    public var minimumRelevance: UInt32
    public var maximumRelevance: UInt32

    public init(minimumRelevance: UInt32 = 0, maximumRelevance: UInt32) {
        self.minimumRelevance = minimumRelevance
        self.maximumRelevance = maximumRelevance
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Minimum Relevance (4 bytes)
        self.minimumRelevance = try dataStream.read(endianess: .littleEndian)
        
        /// Maximum Relevance (4 bytes)
        self.maximumRelevance = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Minimum Relevace (4 bytes)
        dataStream.write(minimumRelevance, endianess: .littleEndian)

        /// Maximum Relevance (4 bytes)
        dataStream.write(maximumRelevance, endianess: .littleEndian)
    }
}
