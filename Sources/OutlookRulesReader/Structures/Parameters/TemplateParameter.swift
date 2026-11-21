//
//  TemplateParameter.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream
import MAPI

public struct TemplateParameter: RuleParameter {
    public var reserved: UInt32 = 0
    /// The entry ID of the message to reply with, exactly as stored. Always written back unchanged.
    public var messageEntryIdBytes: [UInt8]
    /// The entry ID of the message to reply with, decoded; nil if `MAPI` can't decode it. Setting it replaces `messageEntryIdBytes`.
    public var messageEntryId: EntryID? {
        get { RawEntryID.decode(messageEntryIdBytes) }
        set { messageEntryIdBytes = newValue.map(RawEntryID.encode) ?? [] }
    }
    public var name: String
    
    public init(messageEntryId: EntryID, name: String) {
        self.messageEntryIdBytes = RawEntryID.encode(messageEntryId)
        self.name = name
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Message Entry Id (variable)
        self.messageEntryIdBytes = try RawEntryID.read(from: &dataStream)
        
        /// Name (variable)
        self.name = try VersionedString.read(from: &dataStream, version: version)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Message Entry Id (variable)
        RawEntryID.write(messageEntryIdBytes, to: &dataStream)
        
        /// Name (variable)
        VersionedString.write(name, to: &dataStream, version: version)
    }
}
