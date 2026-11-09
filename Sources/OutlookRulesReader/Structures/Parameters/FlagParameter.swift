//
//  FlagParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

/// The "flag message for <action> within <n> days" action (spec §6.21).
public struct FlagParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var days: UInt32
    public var action: String
    /// Always false for this action. See `FlaggedForActionParameter`.
    public var isCondition: Bool = false
    
    public init(action: String, days: UInt32) {
        self.action = action
        self.days = days
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Days (4 bytes)
        self.days = try dataStream.read(endianess: .littleEndian)

        /// Action (variable)
        if version >= .outlook2002 {
            self.action = try UTF16String(dataStream: &dataStream).value
        } else {
            self.action = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Is Condition (4 bytes)
        self.isCondition = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Days (4 bytes)
        dataStream.write(days, endianess: .littleEndian)
        
        /// Action (variable)
        if version >= .outlook2002 {
            UTF16String(value: action).write(to: &dataStream)
        } else {
            ASCIIString(value: action).write(to: &dataStream)
        }
        
        /// Is Condition (4 bytes)
        dataStream.write((isCondition ? 1 : 0) as UInt32, endianess: .littleEndian)
    }
}
