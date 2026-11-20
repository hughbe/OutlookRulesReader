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
    /// The folder's entry ID, exactly as stored. Always written back unchanged.
    public var folderEntryIdBytes: [UInt8]
    /// The folder's entry ID, decoded; nil if `MAPI` can't decode it. Setting it replaces `folderEntryIdBytes`.
    public var folderEntryId: EntryID? {
        get { RawEntryID.decode(folderEntryIdBytes) }
        set { folderEntryIdBytes = newValue.map(RawEntryID.encode) ?? [] }
    }
    /// The entry ID of the store that holds the folder, exactly as stored. Always written back unchanged.
    public var storeEntryIdBytes: [UInt8]
    /// The entry ID of the store that holds the folder, decoded; nil if `MAPI` can't decode it. Setting it replaces `storeEntryIdBytes`.
    public var storeEntryId: EntryID? {
        get { RawEntryID.decode(storeEntryIdBytes) }
        set { storeEntryIdBytes = newValue.map(RawEntryID.encode) ?? [] }
    }
    public var folderName: String
    public var secondaryStore: Bool? {
        get { rawSecondaryStore.map { $0 != 0 } }
        set { if newValue != secondaryStore { rawSecondaryStore = newValue.map { $0 ? 1 : 0 } } }
    }
    /// The stored value of `secondaryStore`, or nil in formats without it. Any non-zero value means true; it is kept so
    /// that the file round-trips exactly.
    public var rawSecondaryStore: UInt32? = 0
    
    public init(folderEntryId: FolderEntryID, storeEntryId: StoreEntryID, folderName: String) {
        self.folderEntryIdBytes = RawEntryID.encode(folderEntryId)
        self.storeEntryIdBytes = RawEntryID.encode(storeEntryId)
        self.folderName = folderName
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Folder Entry Id (variable)
        self.folderEntryIdBytes = try RawEntryID.read(from: &dataStream)
        
        /// Store Entry Id (variable)
        self.storeEntryIdBytes = try RawEntryID.read(from: &dataStream)

        /// Folder Name (variable)
        if version >= .outlook2002 {
            self.folderName = try UTF16String(dataStream: &dataStream).value
        } else {
            self.folderName = try ASCIIString(dataStream: &dataStream).value
        }
        
        if FolderParameter.hasSecondaryStore(version) {
            /// Secondary User Store (4 bytes)
            self.rawSecondaryStore = try dataStream.read(endianess: .littleEndian)
        } else {
            self.rawSecondaryStore = nil
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Folder Entry Id (Variable)
        RawEntryID.write(folderEntryIdBytes, to: &dataStream)
        
        /// Store Entry Id (variable)
        RawEntryID.write(storeEntryIdBytes, to: &dataStream)
        
        /// Folder Name (variable)
        if version >= .outlook2002 {
            UTF16String(value: folderName).write(to: &dataStream)
        } else {
            ASCIIString(value: folderName).write(to: &dataStream)
        }
        
        if FolderParameter.hasSecondaryStore(version) {
            /// Secondary User Store (4 bytes)
            dataStream.write(rawSecondaryStore ?? 0, endianess: .littleEndian)
        }
    }

    /// The secondary-store field was added in version 970718 (spec §6.19), so Outlook 97's formats and the
    /// version-0 format (signature zero) don't have it.
    static func hasSecondaryStore(_ version: OutlookRulesVersion) -> Bool {
        return version != .outlook97 && version != .outlook97Profile && version != .signatureZero
    }
}
