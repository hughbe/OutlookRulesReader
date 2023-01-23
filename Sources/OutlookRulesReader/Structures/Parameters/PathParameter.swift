//
//  PathParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct PathParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 +  UTF16String(value: path).dataSize
    }

    public var reserved: UInt32 = 0
    public var path: String
    
    public init(path: String) {
        self.path = path
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Path (variable)
        if version >= .outlook2002 {
            self.path = try UTF16String(dataStream: &dataStream).value
        } else {
            self.path = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Path (variable)
        if version >= .outlook2002 {
            UTF16String(value: path).write(to: &dataStream)
        } else {
            ASCIIString(value: path).write(to: &dataStream)
        }
    }
}
