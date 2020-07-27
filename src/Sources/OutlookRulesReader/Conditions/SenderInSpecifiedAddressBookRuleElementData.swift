//
//  SenderInSpecifiedAddressBookRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct SenderInSpecifiedAddressBookRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 12
        baseSize += UInt32(storageId.count)
        baseSize += UTF16String(value: name).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var storageIdLength: UInt32
    public var storageId: [UInt8]
    public var name: String
    
    public init(storageId: [UInt8], name: String) {
        self.storageIdLength = UInt32(storageId.count)
        self.storageId = storageId
        self.name = name
    }

    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Storage Length (4 bytes)
        storageIdLength = try dataStream.read(endianess: .littleEndian)
        
        // Storage (variable)
        storageId = try dataStream.readBytes(count: Int(storageIdLength))
        
        // Name (variable)
        name = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Storage Length (4 bytes)
        dataStream.write(storageIdLength, endianess: .littleEndian)
        
        // Storage (variable)
        dataStream.write(storageId)
        
        // Name (variable)
        UTF16String(value: name).write(to: &dataStream)
    }
}
