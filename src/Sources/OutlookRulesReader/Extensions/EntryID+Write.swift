//
//  EntryID+Write.swift
//  
//
//  Created by Hugh Bellamy on 29/01/2021.
//

import DataStream
import MAPI

internal extension StoreEntryID {
    var dataSize: UInt32 {
        /// Flags (4 bytes) + ProviderUid (16 bytes) + Version (1 byte) + Flag (1 byte) + WrappedFlags (4 bytes) + WrappedProviderUid (16 bytes) + WrappedType (4 bytes)
        var baseSize: UInt32 = 4 + 16 + 1 + 1 + 4 + 16 + 4
        baseSize += UInt32(dllFileName.count)
        baseSize += (UInt32(path.count) + 1) * 2
        return baseSize
    }
    
    func write(to dataStream: inout OutputDataStream) {
        dataStream.write(flags, endianess: .littleEndian)
        dataStream.write(providerUid)
        dataStream.write(flag, endianess: .littleEndian)
        dataStream.write(dllFileName, encoding: .ascii)
        dataStream.write(wrappedFlags, endianess: .littleEndian)
        dataStream.write(wrappedProviderUid)
        dataStream.write(wrappedType.rawValue, endianess: .littleEndian)
        dataStream.write(path, encoding: .utf16LittleEndian)
    }
}

internal extension FolderEntryID {
    var dataSize: UInt32 {
        /// Flags (4 bytes) + ProviderUid (16 bytes) + Folder Type (2 bytes) + DatabaseGuid (16 bytes) + Global Counter (8 bytes)
        return 4 + 16 + 2 + 16 + 8
    }
    
    func write(to dataStream: inout OutputDataStream) {
        dataStream.write(flags, endianess: .littleEndian)
        dataStream.write(providerUid)
        dataStream.write(folderType.rawValue, endianess: .littleEndian)
        dataStream.write(databaseGuid)
        dataStream.write(globalCounter, endianess: .littleEndian)
    }
}

internal extension MessageEntryID {
    var dataSize: UInt32 {
        /// Flags (4 bytes) + ProviderUid (16 bytes) + MessageType (2 bytes) + FolderDatabaseGuid (16 bytes) + FolderGlobalCounter (8 bytes) + MessageDatabaseGuid (16 bytes) + MessageGlobalCounter (8 bytes)
        return 4 + 16 + 2 + 16 + 8 + 16 + 8
    }
    
    func write(to dataStream: inout OutputDataStream) {
        dataStream.write(flags, endianess: .littleEndian)
        dataStream.write(providerUid)
        dataStream.write(messageType.rawValue, endianess: .littleEndian)
        dataStream.write(folderDatabaseGuid)
        dataStream.write(folderGlobalCounter, endianess: .littleEndian)
        dataStream.write(messageDatabaseGuid)
        dataStream.write(messageGlobalCounter, endianess: .littleEndian)
    }
}
