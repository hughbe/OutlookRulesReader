//
//  AddressBookParameter.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import MAPI

public struct AddressBookParameter: RuleParameter {
    public var reserved: UInt32 = 0
    /// The address book's entry ID, exactly as stored. Always written back unchanged.
    public var entryIdBytes: [UInt8]
    /// The address book's entry ID, decoded; nil if `MAPI` can't decode it. Setting it replaces `entryIdBytes`.
    public var entryId: EntryID? {
        get { RawEntryID.decode(entryIdBytes) }
        set { entryIdBytes = newValue.map(RawEntryID.encode) ?? [] }
    }
    public var name: String
    
    public init(entryId: EntryID, name: String) {
        self.entryIdBytes = RawEntryID.encode(entryId)
        self.name = name
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Entry Id (4 bytes)
        self.entryIdBytes = try RawEntryID.read(from: &dataStream)
        
        /// Name (variable)
        self.name = try VersionedString.read(from: &dataStream, version: version)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        RawEntryID.write(entryIdBytes, to: &dataStream)
        
        /// Name (variable)
        VersionedString.write(name, to: &dataStream, version: version)
    }
}
