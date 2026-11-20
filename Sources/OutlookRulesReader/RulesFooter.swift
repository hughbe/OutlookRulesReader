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
    /// Probably the time the rules were last saved (spec §4.4). Usually null.
    public var timestamp: OleDateTime = OleDateTime()
    public var unknown: UInt32 = 0
    /// Any bytes after the footer. Outlook doesn't write any, but they are kept so that the file round-trips.
    public var trailingData: Data = Data()
    
    public init(templateDirectory: String = "") {
        self.templateDirectory = templateDirectory
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Template Directory Length (4 bytes)
        /// Outlook keeps this at most MAX_PATH (260), but read whatever length is declared so that the
        /// fields that follow stay aligned.
        let templateDirectoryLength: UInt32 = try dataStream.read(endianess: .littleEndian)
        guard Int(templateDirectoryLength) <= dataStream.remainingCount / (version >= .outlook2002 ? 2 : 1) else {
            throw OutlookRulesReadError.lengthOutOfRange
        }
        
        /// Template (variable)
        if version >= .outlook2002 {
            self.templateDirectory = try UTF16Decoding.decode(try dataStream.readBytes(count: Int(templateDirectoryLength) * 2))
        } else {
            self.templateDirectory = ANSIEncoding.decode(try dataStream.readBytes(count: Int(templateDirectoryLength)))
        }
        
        /// Timestamp (12 bytes)
        self.timestamp = try OleDateTime(dataStream: &dataStream)
        
        /// Unknown (4 bytes)
        self.unknown = try dataStream.read(endianess: .littleEndian)
        
        /// Trailing Data (variable)
        self.trailingData = Data(try dataStream.readBytes(count: dataStream.remainingCount))
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// The length is measured in UTF-16 code units (Outlook 2002 and above) or bytes (earlier versions).
        let length: Int
        let bytes: Data
        if version >= .outlook2002 {
            length = templateDirectory.utf16.count
            bytes = templateDirectory.data(using: .utf16LittleEndian) ?? Data()
        } else {
            bytes = Data(ANSIEncoding.encode(templateDirectory))
            length = bytes.count
        }
        
        /// Template Directory Length (4 bytes)
        dataStream.write(UInt32(length), endianess: .littleEndian)
        
        /// Template Directory (variable)
        dataStream.write(bytes)

        /// Timestamp (12 bytes)
        timestamp.write(to: &dataStream)

        /// Unknown (4 bytes)
        dataStream.write(unknown, endianess: .littleEndian)

        /// Trailing Data (variable)
        dataStream.write(trailingData)
    }
}
