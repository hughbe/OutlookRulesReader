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
    public var entryId: EntryID
    public var name: String
    
    public init(entryId: EntryID, name: String) {
        self.entryId = entryId
        self.name = name
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Entry Id (4 bytes)
        self.entryId = try FlatEntry(dataStream: &dataStream).entryID
        
        /// Name (variable)
        self.name = try VersionedString.read(from: &dataStream, version: version)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        FlatEntry(entryID: entryId).write(to: &dataStream)
        
        /// Name (variable)
        VersionedString.write(name, to: &dataStream, version: version)
    }
}
