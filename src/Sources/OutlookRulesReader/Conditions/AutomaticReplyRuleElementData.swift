//
//  AutomaticReplyRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream
import MAPI

public struct AutomaticReplyRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
        baseSize += 4 + messageEntryId.dataSize
        baseSize += UTF16String(value: name).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var messageEntryIdSize: UInt32
    public var messageEntryId: MessageEntryID
    public var name: String
    
    public init(messageEntryId: MessageEntryID, name: String) {
        self.messageEntryIdSize = messageEntryId.dataSize
        self.messageEntryId = messageEntryId
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)

        /// Message Entry Id Size (4 bytes)
        self.messageEntryIdSize = try dataStream.read(endianess: .littleEndian)
        guard self.messageEntryIdSize == 70 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Message Entry Id (Variable)
        self.messageEntryId = try MessageEntryID(dataStream: &dataStream, size: Int(self.messageEntryIdSize))
        
        /// Name (Variable)
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

        /// Message Entry Id Size (4 bytes)
        dataStream.write(messageEntryIdSize, endianess: .littleEndian)
        
        /// Message Entry Id (Variable)
        messageEntryId.write(to: &dataStream)
        
        /// Name (Variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
