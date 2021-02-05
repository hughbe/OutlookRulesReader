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

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var path: String
    
    public init(path: String) {
        self.path = path
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Path (variable)
        if version >= .outlook2002 {
            self.path = try UTF16String(dataStream: &dataStream).value
        } else {
            self.path = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Path (variable)
        UTF16String(value: path).write(to: &dataStream)
    }
}
