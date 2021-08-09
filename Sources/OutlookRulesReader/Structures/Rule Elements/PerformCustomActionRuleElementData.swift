//
//  PerformCustomActionRuleElementData.swift
//  
//
//  Created by Hugh Bellamy on 31/01/2021.
//

import DataStream

public struct PerformCustomActionRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
        baseSize += UTF16String(value: location).dataSize
        baseSize += UTF16String(value: name).dataSize
        baseSize += UTF16String(value: actionValue).dataSize
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var location: String
    public var name: String
    public var options: String
    public var actionValue: String
    
    public init(location: String, name: String, options: String = "", actionValue: String = "") {
        self.location = location
        self.name = name
        self.options = options
        self.actionValue = actionValue
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
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
            self.actionValue = try UTF16String(dataStream: &dataStream).value
        } else {
            self.actionValue = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Location (variable)
        UTF16String(value: location).write(to: &dataStream)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
        
        /// Options (variable)
        UTF16String(value: options).write(to: &dataStream)
        
        /// Action Value (variable)
        UTF16String(value: actionValue).write(to: &dataStream)
    }
}
