//
//  FolderParameter.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import MAPI

public struct FolderParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var folderEntryId: EntryID
    public var storeEntryId: EntryID
    public var folderName: String
    public var secondaryStore: Bool? = false
    
    public init(folderEntryId: FolderEntryID, storeEntryId: StoreEntryID, folderName: String) {
        self.folderEntryId = folderEntryId
        self.storeEntryId = storeEntryId
        self.folderName = folderName
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Folder Entry Id (variable)
        self.folderEntryId = try FlatEntry(dataStream: &dataStream).entryID
        
        /// Store Entry Id (variable)
        self.storeEntryId = try FlatEntry(dataStream: &dataStream).entryID

        /// Folder Name (variable)
        if version >= .outlook2002 {
            self.folderName = try UTF16String(dataStream: &dataStream).value
        } else {
            self.folderName = try ASCIIString(dataStream: &dataStream).value
        }
        
        if FolderParameter.hasSecondaryStore(version) {
            /// Secondary User Store (4 bytes)
            self.secondaryStore = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
        } else {
            self.secondaryStore = nil
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Folder Entry Id (Variable)
        FlatEntry(entryID: folderEntryId).write(to: &dataStream)
        
        /// Store Entry Id (4 bytes)
        FlatEntry(entryID: storeEntryId).write(to: &dataStream)
        
        /// Folder Name (variable)
        if version >= .outlook2002 {
            UTF16String(value: folderName).write(to: &dataStream)
        } else {
            ASCIIString(value: folderName).write(to: &dataStream)
        }
        
        if FolderParameter.hasSecondaryStore(version) {
            /// Secondary User Store (4 bytes)
            dataStream.write(((secondaryStore ?? false) ? 1 : 0) as UInt32, endianess: .littleEndian)
        }
    }

    /// The secondary-store field was added in version 970718 (spec §6.19), so Outlook 97's formats don't have it.
    /// Signature-0 streams are assumed to have it.
    static func hasSecondaryStore(_ version: OutlookRulesVersion) -> Bool {
        return version != .outlook97 && version != .outlook97Profile
    }
}
