//
//  RulesFooter.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import Foundation
import WindowsDataTypes

internal struct RulesFooter {
    public var templateDirectory: String = ""
    public var rawCreationStatus: UInt32 = 2
    public var creationStatus: CreationStatus {
        return CreationStatus(rawValue: rawCreationStatus)!
    }
    public var rawCreationDate: Double = 0
    public var creationDate: Date {
        return Date(timestamp: rawCreationDate)
    }
    public var unknown: UInt32 = 0
    
    public init(templateDirectory: String = "") {
        self.templateDirectory = templateDirectory
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Template Directory Length (4 bytes)
        let templateDirectoryLengthRaw: UInt32 = try dataStream.read(endianess: .littleEndian)
        let templateDirectoryLength = min(templateDirectoryLengthRaw, 260)
        guard templateDirectoryLength * (version >= .outlook2002 ? 2 : 1) <= dataStream.remainingCount else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Template (variable)
        if version >= .outlook2002 {
            guard let templateDirectory = try dataStream.readString(count: Int(templateDirectoryLength) * 2, encoding: .utf16LittleEndian) else {
                throw OutlookRulesReadError.corrupted
            }

            self.templateDirectory = templateDirectory
        } else {
            guard let templateDirectory = try dataStream.readString(count: Int(templateDirectoryLength), encoding: .ascii) else {
                throw OutlookRulesReadError.corrupted
            }

            self.templateDirectory = templateDirectory
        }
        
        /// Creation Status (4 bytes)
        self.rawCreationStatus = try dataStream.read(endianess: .littleEndian)
        
        /// Creation Date (8 bytes)
        self.rawCreationDate = try dataStream.readDouble(endianess: .littleEndian)
        
        /// Unknown (4 bytes)
        self.unknown = try dataStream.read(endianess: .littleEndian)
        
        assert(dataStream.remainingCount == 0)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Template Directory Length (4 bytes)
        dataStream.write(UInt32(templateDirectory.count), endianess: .littleEndian)
        
        /// Template Directory (variable)
        dataStream.write(templateDirectory, encoding: .utf16LittleEndian)
        
        /// Status (4 bytes)
        dataStream.write(rawCreationStatus, endianess: .littleEndian)

        /// Creation Date (8 bytes)
        dataStream.write(rawCreationDate, endianess: .littleEndian)

        /// Unknown (4 bytes)
        dataStream.write(unknown, endianess: .littleEndian)
    }
    
    public enum CreationStatus: UInt32 {
        case created = 0x00000000
        case notCreated = 0x00000002
    }
}
