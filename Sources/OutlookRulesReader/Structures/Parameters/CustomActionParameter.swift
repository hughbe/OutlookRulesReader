//
//  CustomActionParameter.swift
//  
//
//  Created by Hugh Bellamy on 31/01/2021.
//

import DataStream

public struct CustomActionParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var location: String
    public var name: String
    public var options: String
    public var value: String
    
    public init(location: String, name: String, options: String = "", value: String = "") {
        self.location = location
        self.name = name
        self.options = options
        self.value = value
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Location (variable)
        if version >= .outlook2002 {
            self.location = try UTF16String(dataStream: &dataStream).value
        } else {
            self.location = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Name (variable)
        if version >= .outlook2002 {
            self.name = try UTF16String(dataStream: &dataStream).value
        } else {
            self.name = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Options (variable)
        if version >= .outlook2002 {
            self.options = try UTF16String(dataStream: &dataStream).value
        } else {
            self.options = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Action Value (variable)
        if version >= .outlook2002 {
            self.value = try UTF16String(dataStream: &dataStream).value
        } else {
            self.value = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Location (variable)
        if version >= .outlook2002 {
            UTF16String(value: location).write(to: &dataStream)
        } else {
            ASCIIString(value: location).write(to: &dataStream)
        }
        
        /// Name (variable)
        if version >= .outlook2002 {
            UTF16String(value: name).write(to: &dataStream)
        } else {
            ASCIIString(value: name).write(to: &dataStream)
        }
        
        /// Options (variable)
        if version >= .outlook2002 {
            UTF16String(value: options).write(to: &dataStream)
        } else {
            ASCIIString(value: options).write(to: &dataStream)
        }
        
        /// Action Value (variable)
        if version >= .outlook2002 {
            UTF16String(value: value).write(to: &dataStream)
        } else {
            ASCIIString(value: value).write(to: &dataStream)
        }
    }
}
