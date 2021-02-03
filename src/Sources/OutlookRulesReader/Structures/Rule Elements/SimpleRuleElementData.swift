//
//  SimpleRuleElementData.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct SimpleRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 4
    }

    public var reserved: UInt32
    
    public init() {
        self.reserved = 0
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
    }
}
