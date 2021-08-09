//
//  PathRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct PathRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        return 8 + UTF16String(value: path).dataSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var path: String
    
    public init(path: String) {
        self.path = path
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Path (variable)
        if version >= .outlook2002 {
            self.path = try UTF16String(dataStream: &dataStream).value
        } else {
            self.path = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Path (variable)
        UTF16String(value: path).write(to: &dataStream)
    }
}
