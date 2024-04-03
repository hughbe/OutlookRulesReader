//
//  FormTypeParameter.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream

public struct FormTypeParameter: RuleParameter {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        baseSize += UTF16String(value: name).dataSize
        baseSize += ASCIIString(value: className).dataSize
        return baseSize
    }

    public var reserved: UInt32 = 0
    public var name: String
    public var className: String
    
    public init(name: String, className: String) {
        self.name = name
        self.className = className
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Name (variable)
        if version >= .outlook2002 {
            self.name = try UTF16String(dataStream: &dataStream).value
        } else {
            self.name = try ASCIIString(dataStream: &dataStream).value
        }

        /// Class Name (variable)
        self.className = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Name (variable)
        if version >= .outlook2002 {
            UTF16String(value: name).write(to: &dataStream)
        } else {
            ASCIIString(value: name).write(to: &dataStream)
        }

        /// Class Name (variable)
        ASCIIString(value: name).write(to: &dataStream)
    }
}
