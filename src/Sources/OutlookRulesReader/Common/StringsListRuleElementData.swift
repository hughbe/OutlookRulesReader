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
        // Flags (4 bytes)
        flags = try dataStream.read(endianess: .littleEndian)
        
        // Value (variable)
        value = try UTF16String(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Flags (4 bytes)
        dataStream.write(flags, endianess: .littleEndian)
        
        // Value (variable)
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
    
    public var numberOfEntries: UInt32
    public var entries: [String]
    
    public init(entries: [String]) {
        self.numberOfEntries = UInt32(entries.count)
        self.entries = entries
    }
    
    public init(dataStream: inout DataStream) throws {
        // Number of entries (4 bytes)
        numberOfEntries = try dataStream.read(endianess: .littleEndian)
        
        // Entries (variable)
        entries = []
        entries.reserveCapacity(Int(numberOfEntries))
        for _ in 0..<numberOfEntries {
            let entry = try SearchEntry(dataStream: &dataStream)
            entries.append(entry.value)
        }
    }

    public func write(to dataStream: inout OutputDataStream) {
        // Number of entries (4 bytes)
        dataStream.write(UInt32(entries.count), endianess: .littleEndian)
        
        for entry in entries {
            SearchEntry(value: entry).write(to: &dataStream)
        }
    }
}
