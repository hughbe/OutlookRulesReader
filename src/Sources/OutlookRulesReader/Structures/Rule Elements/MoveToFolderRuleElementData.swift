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
        baseSize += 4 + UInt32(folderEntryId.dataSize)
        baseSize += 4 + UInt32(storeEntryId.dataSize)
        baseSize += UTF16String(value: folderName).dataSize
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var folderEntryIdSize: UInt32
    public var folderEntryId: EntryID
    public var storeEntryIdSize: UInt32
    public var storeEntryId: StoreEntryID
    public var folderName: String
    public var unknown: UInt32? = 0
    
    public init(folderEntryId: FolderEntryID, storeEntryId: StoreEntryID, folderName: String) {
        self.folderEntryIdSize = UInt32(folderEntryId.dataSize)
        self.folderEntryId = folderEntryId
        self.storeEntryIdSize = UInt32(storeEntryId.dataSize)
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
        
        /// Folder Entry Id Size (4 bytes)
        self.folderEntryIdSize = try dataStream.read(endianess: .littleEndian)
        guard self.folderEntryIdSize <= dataStream.remainingCount else {
            throw OutlookRulesReadError.corrupted
        }
        
        let folderEntryIdStartPosition = dataStream.position
        
        /// Folder Entry Id (variable)
        self.folderEntryId = try getEntryID(dataStream: &dataStream, size: Int(self.folderEntryIdSize))
        
        guard dataStream.position - folderEntryIdStartPosition == self.folderEntryIdSize else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Store Entry Id Size (4 bytes)
        self.storeEntryIdSize = try dataStream.read(endianess: .littleEndian)
        guard self.storeEntryIdSize <= dataStream.remainingCount else {
            throw OutlookRulesReadError.corrupted
        }
        
        let storeEntryIdStartPosition = dataStream.position
        
        /// Store EntryId (variable)
        self.storeEntryId = try StoreEntryID(dataStream: &dataStream, size: Int(self.storeEntryIdSize))
        
        guard dataStream.position - storeEntryIdStartPosition == self.storeEntryIdSize else {
            throw OutlookRulesReadError.corrupted
        }

        /// Folder Name (variable)
        if version >= .outlook2002 {
            self.folderName = try UTF16String(dataStream: &dataStream).value
        } else {
            self.folderName = try ASCIIString(dataStream: &dataStream).value
        }
        
        if version != .noSignature {
            /// Unknown (4 bytes)
            self.unknown = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown = nil
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Folder Entry Id Size (4 bytes)
        dataStream.write(folderEntryIdSize, endianess: .littleEndian)
        
        /// Folder Entry Id (variable)
        folderEntryId.write(to: &dataStream)
        
        /// Store Entry Id Size (4 bytes)
        dataStream.write(storeEntryIdSize, endianess: .littleEndian)
        
        /// Store Id (variable)
        storeEntryId.write(to: &dataStream)
        
        /// Folder Name (variable)
        UTF16String(value: folderName).write(to: &dataStream)
        
        if let unknown = unknown {
            /// Unknown (4 bytes)
            dataStream.write(unknown, endianess: .littleEndian)
        }
    }
}
