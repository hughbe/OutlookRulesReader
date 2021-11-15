//
//  FlagForFollowUpParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

/// Specifies the time period for which an Outlook item is marked as a task.
public enum FollowUp: UInt32 {
    case today = 0x00000001
    case tomorrow = 0x00000002
    case thisWeek = 0x00000003
    case nextWeek = 0x00000004
    case noDate = 0x00000007
    case completed = 0x0000000A
}

public struct FlagForFollowUpParameter: RuleParameter {
    public var dataSize: UInt32 {
        4 + UTF16String(value: actionName).dataSize
    }

    public var reserved: UInt32 = 0
    public var rawFollowUp: UInt32
    public var followUp: FollowUp {
        get {
            return FollowUp(rawValue: rawFollowUp)!
        } set {
            rawFollowUp = newValue.rawValue
        }
    }
    public var actionName: String
    
    public init(action: String, followUp: FollowUp) {
        self.actionName = action
        self.rawFollowUp = followUp.rawValue
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Follow Up (4 bytes)
        self.rawFollowUp = try dataStream.read(endianess: .littleEndian)

        /// Action Name (variable)
        self.actionName = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Follow Up (4 bytes)
        dataStream.write(rawFollowUp, endianess: .littleEndian)
        
        /// Action Name (variable)
        UTF16String(value: actionName).write(to: &dataStream)
    }
}
