//
//  RulesFooter.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import WindowsDataTypes

internal struct RulesFooter {
    public var templateDirectory: String = ""
    public var unknown1: UInt32 = 2
    public var creationDate: Double = 0
    public var unknown4: UInt32 = 0
    
    public init(templateDirectory: String = "") {
        self.templateDirectory = templateDirectory
    }
    
    public init(dataStream: inout DataStream) throws {
        /// Template Directory Length (4 bytes)
        let templateDirectoryLength = try dataStream.read(endianess: .littleEndian) as UInt32
        guard templateDirectoryLength <= dataStream.remainingCount else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Template (variable)
        guard let templateDirectory = try dataStream.readString(count: Int(templateDirectoryLength) * 2, encoding: .utf16LittleEndian) else {
            throw OutlookRulesReadError.corrupted
        }
        self.templateDirectory = templateDirectory
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)
        
        /// Creation Date (8 bytes)
        self.creationDate = try dataStream.readDouble(endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        self.unknown4 = try dataStream.read(endianess: .littleEndian)
        
        assert(dataStream.remainingCount == 0)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Template Directory Length (4 bytes)
        dataStream.write(UInt32(templateDirectory.count), endianess: .littleEndian)
        
        // Template Directory (variable)
        dataStream.write(templateDirectory, encoding: .utf16LittleEndian)
        
        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)

        // Creation Date (8 bytes)
        dataStream.write(creationDate, endianess: .littleEndian)

        // Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)
    }
}
