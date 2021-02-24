//
//  MoveToFolderRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import MAPI

public struct MoveToFolderRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
        baseSize += UInt32(FlatEntry(entryID: folderEntryId).dataSize)
        baseSize += UInt32(FlatEntry(entryID: storeEntryId).dataSize)
        baseSize += UTF16String(value: folderName).dataSize
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var folderEntryId: EntryID
    public var storeEntryId: EntryID
    public var folderName: String
    public var secondaryUserStore: Bool? = false
    
    public init(folderEntryId: FolderEntryID, storeEntryId: StoreEntryID, folderName: String) {
        self.folderEntryId = folderEntryId
        self.storeEntryId = storeEntryId
        self.folderName = folderName
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
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
        
        if version != .noSignature {
            /// Secondary User Store (4 bytes)
            self.secondaryUserStore = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
        } else {
            self.secondaryUserStore = nil
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Folder Entry Id (Variable)
        FlatEntry(entryID: folderEntryId).write(to: &dataStream)
        
        /// Store Entry Id (4 bytes)
        FlatEntry(entryID: storeEntryId).write(to: &dataStream)
        
        /// Folder Name (variable)
        UTF16String(value: folderName).write(to: &dataStream)
        
        if let secondaryUserStore = secondaryUserStore {
            /// Secondary User Store (4 bytes)
            dataStream.write((secondaryUserStore ? 1 : 0) as UInt32, endianess: .littleEndian)
        }
    }
}
