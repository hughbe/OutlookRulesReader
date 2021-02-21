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
        var baseSize: UInt32 = 12
        baseSize += UInt32(messageEntryId.dataSize)
        baseSize += UTF16String(value: name).dataSize
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var messageEntryIdSize: UInt32
    public var messageEntryId: MessageEntryID
    public var name: String
    
    public init(messageEntryId: MessageEntryID, name: String) {
        self.messageEntryIdSize = UInt32(messageEntryId.dataSize)
        self.messageEntryId = messageEntryId
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Message Entry Id Size (4 bytes)
        self.messageEntryIdSize = try dataStream.read(endianess: .littleEndian)
        guard self.messageEntryIdSize == 70 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Message Entry Id (variable)
        self.messageEntryId = try MessageEntryID(dataStream: &dataStream, size: Int(self.messageEntryIdSize))
        
        /// Name (variable)
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)

        /// Message Entry Id Size (4 bytes)
        dataStream.write(messageEntryIdSize, endianess: .littleEndian)
        
        /// Message Entry Id (variable)
        messageEntryId.write(to: &dataStream)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
