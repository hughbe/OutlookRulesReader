//
//  StringsListRuleElementData.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

internal struct SearchEntry {
    public var dataSize: UInt32 {
        return 4 + UTF16String(value: value).dataSize
    }
    
    public var flags: UInt32 = 0
    public var value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init(dataStream: inout DataStream) throws {
        /// Flags (4 bytes)
        self.flags = try dataStream.read(endianess: .littleEndian)
        
        /// Value (variable)
        self.value = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Flags (4 bytes)
        dataStream.write(flags, endianess: .littleEndian)
        
        /// Value (variable)
        UTF16String(value: value).write(to: &dataStream)
    }
}

public struct StringsListRuleElementData: RuleElementData {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        for entry in entries {
            baseSize += UTF16String(value: entry).dataSize
        }
        
        return baseSize
    }
    
    public var entries: [String]
    
    public init(entries: [String]) {
        self.entries = entries
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Number of entries (4 bytes)
        let numberOfEntries: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Entries (variable)
        var entries: [String] = []
        entries.reserveCapacity(Int(numberOfEntries))
        for _ in 0..<numberOfEntries {
            let entry = try SearchEntry(dataStream: &dataStream)
            entries.append(entry.value)
        }
        
        self.entries = entries
    }

    public func write(to dataStream: inout OutputDataStream) {
        /// Number of entries (4 bytes)
        dataStream.write(UInt32(entries.count), endianess: .littleEndian)
        
        /// Entries (variable)
        for entry in entries {
            SearchEntry(value: entry).write(to: &dataStream)
        }
    }
}
