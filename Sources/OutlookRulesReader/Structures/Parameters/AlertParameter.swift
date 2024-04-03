//
//  AlertParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct AlertParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 +  UTF16String(value: name).dataSize
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
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
