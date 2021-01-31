//
//  PeformCustomActionRuleElementData.swift
//  
//
//  Created by Hugh Bellamy on 31/01/2021.
//

import DataStream

public struct PeformCustomActionRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
        baseSize += UTF16String(value: location).dataSize
        baseSize += UTF16String(value: name).dataSize
        baseSize += UTF16String(value: actionValue).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
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
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Location (Variable)
        self.location = try UTF16String(dataStream: &dataStream).value
        
        /// Name (Variable)
        self.name = try UTF16String(dataStream: &dataStream).value
        
        /// Options (Variable)
        self.options = try UTF16String(dataStream: &dataStream).value
        
        /// Action Value (Variable)
        self.actionValue = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Location (Variable)
        UTF16String(value: location).write(to: &dataStream)
        
        /// Name (Variable)
        UTF16String(value: name).write(to: &dataStream)
        
        /// Options (Variable)
        UTF16String(value: options).write(to: &dataStream)
        
        /// Action Value (Variable)
        UTF16String(value: actionValue).write(to: &dataStream)
    }
}
