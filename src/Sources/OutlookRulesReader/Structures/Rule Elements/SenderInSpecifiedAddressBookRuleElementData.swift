//
//  SenderInSpecifiedAddressBookRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import MAPI

public struct SenderInSpecifiedAddressBookRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 12
        baseSize += UInt32(FlatEntry(entryID: entryId).dataSize)
        baseSize += UTF16String(value: name).dataSize
        return baseSize
    }

    public var extended: UInt32 = 1
    public var reserved: UInt32 = 0
    public var entryId: EntryID
    public var name: String
    
    public init(entryId: EntryID, name: String) {
        self.entryId = entryId
        self.name = name
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Extended (4 bytes)
        self.extended = try dataStream.read(endianess: .littleEndian)
        guard self.extended == 0x00000001 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Entry Id (4 bytes)
        self.entryId = try FlatEntry(dataStream: &dataStream).entryID
        
        /// Name (variable)
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Extended (4 bytes)
        dataStream.write(extended, endianess: .littleEndian)
        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        FlatEntry(entryID: entryId).write(to: &dataStream)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
