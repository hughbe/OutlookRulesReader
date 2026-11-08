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
    public var creationDate: OleDateTime = OleDateTime()
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
        
        /// Creation Date (12 bytes)
        self.creationDate = try OleDateTime(dataStream: &dataStream)
        
        /// Unknown (4 bytes)
        self.unknown = try dataStream.read(endianess: .littleEndian)
        
        assert(dataStream.remainingCount == 0)
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// The length is measured in UTF-16 code units (Outlook 2002 and above) or bytes (earlier versions).
        let length: Int
        let bytes: Data
        if version >= .outlook2002 {
            length = templateDirectory.utf16.count
            bytes = templateDirectory.data(using: .utf16LittleEndian) ?? Data()
        } else {
            bytes = templateDirectory.data(using: .isoLatin1, allowLossyConversion: true) ?? Data()
            length = bytes.count
        }
        
        /// Template Directory Length (4 bytes)
        dataStream.write(UInt32(length), endianess: .littleEndian)
        
        /// Template Directory (variable)
        dataStream.write(bytes)

        /// Creation Date (12 bytes)
        creationDate.write(to: &dataStream)

        /// Unknown (4 bytes)
        dataStream.write(unknown, endianess: .littleEndian)
    }
}
