//
//  StringParameter.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct StringParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 + UTF16String(value: value).dataSize
    }
    
    public var flags: UInt32 = 0
    public var value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Flags (4 bytes)
        self.flags = try dataStream.read(endianess: .littleEndian)
        
        /// Value (variable)
        if version >= .outlook2002 {
            self.value = try UTF16String(dataStream: &dataStream).value
        } else {
            self.value = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Flags (4 bytes)
        dataStream.write(flags, endianess: .littleEndian)
        
        /// Value (variable)
        UTF16String(value: value).write(to: &dataStream)
    }
}
