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
        baseSize += UInt32(entryId.count)
        baseSize += UTF16String(value: name).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var entryIdSize: UInt32
    public var entryId: [UInt8]
    public var name: String
    
    public init(entryId: [UInt8], name: String) {
        self.entryIdSize = UInt32(entryId.count)
        self.entryId = entryId
        self.name = name
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Entry Id Size (4 bytes)
        self.entryIdSize = try dataStream.read(endianess: .littleEndian)
        
        /// Storage Id (variable)
        self.entryId = try dataStream.readBytes(count: Int(self.entryIdSize))
        
        /// Name (variable)
        self.name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Entry Id Size (4 bytes)
        dataStream.write(entryIdSize, endianess: .littleEndian)
        
        /// Entry id (variable)
        dataStream.write(entryId)
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
