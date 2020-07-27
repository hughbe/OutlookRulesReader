//
//  FlagForFollowUpRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public enum FollowUp: UInt32 {
    case today = 0x00000001
    case tomorrow = 0x00000002
    case thisWeek = 0x00000003
    case nextWeek = 0x00000004
    case noDate = 0x00000007
    case completed = 0x0000000A
}

public struct FlagForFollowUpRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 12
        baseSize += UTF16String(value: actionName).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
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
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Follow Up (4 bytes)
        rawFollowUp = try dataStream.read(endianess: .littleEndian)

        // Action Name (variable)
        actionName = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Follow Up (4 bytes)
        dataStream.write(rawFollowUp, endianess: .littleEndian)
        
        // Action Name (variable)
        UTF16String(value: actionName).write(to: &dataStream)
    }
}
