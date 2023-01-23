//
//  SendersListParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct SendersListParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 +  ASCIIString(value: name).dataSize
    }

    public var reserved: UInt32 = 0
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Name (variable)
        self.name = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Name (variable)
        ASCIIString(value: name).write(to: &dataStream)
    }
}
