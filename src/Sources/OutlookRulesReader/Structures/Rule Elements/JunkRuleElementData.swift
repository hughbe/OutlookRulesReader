//
//  SendersListRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct SendersListRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 8 + ASCIIString(value: name).dataSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Name (variable)
        self.name = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Name (variable)
        ASCIIString(value: name).write(to: &dataStream)
    }
}
