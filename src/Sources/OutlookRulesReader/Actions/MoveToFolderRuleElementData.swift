//
//  MoveToFolderRuleElementData.swift
//
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

public struct MoveToFolderRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 8
        baseSize += 4 + UInt32(folderId.count)
        baseSize += 4 + UInt32(storeId.count)
        baseSize += UTF16String(value: folderName).dataSize
        return baseSize
    }

    public var unknown1: UInt32 = 1
    public var unknown2: UInt32 = 0
    public var folderIdLength: UInt32
    public var folderId: [UInt8]
    public var storeIdLength: UInt32
    public var storeId: [UInt8]
    public var folderName: String
    public var unknown3: UInt32 = 0
    
    public init(folderId: [UInt8], storeId: [UInt8], folderName: String) {
        self.folderIdLength = UInt32(folderId.count)
        self.folderId = folderId
        self.storeIdLength = UInt32(storeId.count)
        self.storeId = storeId
        self.folderName = folderName
    }
    
    public init(dataStream: inout DataStream) throws {
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Folder Id Length (4 bytes)
        folderIdLength = try dataStream.read(endianess: .littleEndian)
        
        // Folder Id (variable)
        folderId = try dataStream.readBytes(count: Int(folderIdLength))
        
        // Store Id Length (4 bytes)
        storeIdLength = try dataStream.read(endianess: .littleEndian)
        
        // Store Id (variable)
        storeId = try dataStream.readBytes(count: Int(storeIdLength))
        
        // Folder Name (variable)
        folderName = try UTF16String(dataStream: &dataStream).value
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Folder Id Length (4 bytes)
        dataStream.write(folderIdLength, endianess: .littleEndian)
        
        // Folder Id (variable)
        dataStream.write(folderId)
        
        // Store Id Length (4 bytes)
        dataStream.write(storeIdLength, endianess: .littleEndian)
        
        // Store Id (variable)
        dataStream.write(storeId)
        
        // Folder Name (variable)
        UTF16String(value: folderName).write(to: &dataStream)
        
        // Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
    }
}
