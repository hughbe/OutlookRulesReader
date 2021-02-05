//
//  Form.swift
//  
//
//  Created by Hugh Bellamy on 04/02/2021.
//

import DataStream

public struct Form {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        baseSize += UTF16String(value: name).dataSize
        baseSize += ASCIIString(value: className).dataSize
        return baseSize
    }

    public var unknown: UInt32 = 0
    public var name: String
    public var className: String
    
    public init(name: String, className: String) {
        self.name = name
        self.className = className
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown (4 bytes)
        self.unknown = try dataStream.read(endianess: .littleEndian)
        
        /// Name (variable)
        if version >= .outlook2002 {
            self.name = try UTF16String(dataStream: &dataStream).value
        } else {
            self.name = try ASCIIString(dataStream: &dataStream).value
        }

        /// Class Name (variable)
        self.className = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown (4 bytes)
        dataStream.write(unknown, endianess: .littleEndian)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)

        /// Class Name (variable)
        ASCIIString(value: name).write(to: &dataStream)
    }
}
