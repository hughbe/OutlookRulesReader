//
//  RulesFooter.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RulesFooter {
    public var templateDirectory: String = ""
    public var unknown1: UInt32 = 2
    public var unknown2: UInt32 = 0
    public var unknown3: UInt32 = 0
    public var unknown4: UInt32 = 0
    
    public init(templateDirectory: String = "") {
        self.templateDirectory = templateDirectory
    }
    
    public init(dataStream: inout DataStream) throws {
        // Template Directory Length (4 bytes)
        let templateDirectoryLength = try dataStream.read(endianess: .littleEndian) as UInt32
        
        // Template (variable)
        guard let templateDirectory = try dataStream.readString(count: Int(templateDirectoryLength) * 2, encoding: .utf16LittleEndian) else {
            throw OutlookRulesFileError.corrupted
        }
        self.templateDirectory = templateDirectory
        
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown4 (4 bytes)
        unknown4 = try dataStream.read(endianess: .littleEndian)
        
        assert(dataStream.remainingCount == 0)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Template Directory Length (4 bytes)
        dataStream.write(UInt32(templateDirectory.count), endianess: .littleEndian)
        
        // Template Directory (variable)
        dataStream.write(templateDirectory, encoding: .utf16LittleEndian)
        
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)

        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)

        // Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)

        // Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)
    }
}

