//
//  EventParameter.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct RuleEventFlags: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init(dataStream: inout DataStream) throws {
        self.rawValue = try dataStream.read(endianess: .littleEndian)
    }
    
    public static let afterReceived = RuleEventFlags(rawValue: 0x01)
    public static let afterSent = RuleEventFlags(rawValue: 0x04)
    public static let afterServerReceived = RuleEventFlags(rawValue: 0x08)
}

public struct EventParameter: RuleParameter {
    public let dataSize: UInt32 = 8

    public var reserved: UInt32 = 0
    public let flags: RuleEventFlags
    
    public init(flags: RuleEventFlags) {
        self.flags = flags
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Flags (4 bytes)
        self.flags = try RuleEventFlags(dataStream: &dataStream)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Flags (4 bytes)
        dataStream.write(flags.rawValue, endianess: .littleEndian)
    }
}
