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

    public var extended: UInt32
    
    public init() {
        self.extended = 0
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
    }
}
