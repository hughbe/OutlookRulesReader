//
//  MessageParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct MessageParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 + UTF16String(value: message).dataSize
    }

    public var reserved: UInt32 = 0
    public var message: String
    
    public init(path: String) {
        self.message = path
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Message (variable)
        if version >= .outlook2002 {
            self.message = try UTF16String(dataStream: &dataStream).value
        } else {
            self.message = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Message (variable)
        if version >= .outlook2002 {
            UTF16String(value: message).write(to: &dataStream)
        } else {
            ASCIIString(value: message).write(to: &dataStream)
        }
    }
}
