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
        baseSize += 4 + folderEntryId.dataSize
        baseSize += 4 + storeEntryId.dataSize
        baseSize += UTF16String(value: folderName).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var folderEntryIdSize: UInt32
    public var folderEntryId: FolderEntryID
    public var storeEntryIdSize: UInt32
    public var storeEntryId: StoreEntryID
    public var folderName: String
    public var unknown3: UInt32 = 0
    
    public init(folderEntryId: FolderEntryID, storeEntryId: StoreEntryID, folderName: String) {
        self.folderEntryIdSize = folderEntryId.dataSize
        self.folderEntryId = folderEntryId
        self.storeEntryIdSize = storeEntryId.dataSize
        self.storeEntryId = storeEntryId
        self.folderName = folderName
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // FolderEntryIdSize (4 bytes)
        self.folderEntryIdSize = try dataStream.read(endianess: .littleEndian)
        if self.folderEntryIdSize != 46 {
            throw OutlookRulesFileError.corrupted
        }
        
        // FolderEntryId (variable)
        self.folderEntryId = try FolderEntryID(dataStream: &dataStream, size: Int(self.folderEntryIdSize))
        
        // StoreEntryIdSize (4 bytes)
        self.storeEntryIdSize = try dataStream.read(endianess: .littleEndian)
        
        // StoreEntryId (variable)
        self.storeEntryId = try StoreEntryID(dataStream: &dataStream, size: Int(self.storeEntryIdSize))
        
        // FolderName (variable)
        self.folderName = try UTF16String(dataStream: &dataStream).value
        
        // Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // FolderEntryIdSize (4 bytes)
        dataStream.write(folderEntryIdSize, endianess: .littleEndian)
        
        // FolderEntryId (variable)
        dataStream.write(folderEntryId)
        
        // StoreEntryIdSize (4 bytes)
        dataStream.write(storeEntryIdSize, endianess: .littleEndian)
        
        // Store Id (variable)
        dataStream.write(storeEntryId)
        
        // Folder Name (variable)
        UTF16String(value: folderName).write(to: &dataStream)
        
        // Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
    }
}

fileprivate extension FolderEntryID {
    var dataSize: UInt32 {
        return 46
    }
}

fileprivate extension StoreEntryID {
    var dataSize: UInt32 {
        // Flags + ProviderUid + Version + Flag + WrappedFlags + WrappedProviderUid + WrappedType
        var baseSize: UInt32 = 4 + 16 + 1 + 1 + 4 + 16 + 4
        baseSize += UInt32(dllFileName.count)
        baseSize += (UInt32(path.count) + 1) * 2
        return baseSize
    }
}
