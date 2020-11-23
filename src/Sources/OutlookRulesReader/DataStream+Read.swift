//
//  DataStream+Read.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import Foundation
import MAPI

extension DataStream {    
    internal mutating func readUInt8Length() throws -> Int {
        // If the value is 0xFF the next 2 bytes read the length of the string.
        let length = try read() as UInt8
        if length < 0xFF {
            return Int(length)
        }
        
        return Int(try read(endianess: .littleEndian) as UInt16)
    }
}

extension OutputDataStream {
    internal mutating func writeUInt8Length(length: Int) {
        // If the value is 0xFF the next 2 bytes read the length of the string.
        if length < 0xFF {
            write(UInt8(length))
            return
        }
        
        write(0xFF)
        write(UInt16(length), endianess: .littleEndian)
    }
    
    internal mutating func write(_ folderEntryId: FolderEntryID) {
        write(folderEntryId.flags, endianess: .littleEndian)
        write(folderEntryId.providerUid)
        write(folderEntryId.folderType.rawValue, endianess: .littleEndian)
        write(folderEntryId.databaseGuid)
        write(folderEntryId.globalCounter, endianess: .littleEndian)
    }
    
    internal mutating func write(_ storeEntryId: StoreEntryID) {
        write(storeEntryId.flags, endianess: .littleEndian)
        write(storeEntryId.providerUid)
        write(storeEntryId.flag, endianess: .littleEndian)
        write(storeEntryId.dllFileName, encoding: .ascii)
        write(storeEntryId.wrappedFlags, endianess: .littleEndian)
        write(storeEntryId.wrappedProviderUid)
        write(storeEntryId.wrappedType, endianess: .littleEndian)
        write(storeEntryId.path, encoding: .utf16LittleEndian)
    }
}
