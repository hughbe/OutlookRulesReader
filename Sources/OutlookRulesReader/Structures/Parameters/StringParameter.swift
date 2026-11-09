//
//  StringParameter.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream

/// One word or phrase for a "with <specific words> in …" condition or exception (spec §6.3). Later versions
/// (at least Outlook 2007) write one parameter per word; Outlook 97 and 98 allow a single phrase per condition.
public struct StringParameter: RuleParameter {
    public var flags: UInt32 = 0
    public var value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Flags (4 bytes)
        self.flags = try dataStream.read(endianess: .littleEndian)
        
        /// Value (variable)
        if version >= .outlook2002 {
            self.value = try UTF16String(dataStream: &dataStream).value
        } else {
            self.value = try ASCIIString(dataStream: &dataStream).value
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Flags (4 bytes)
        dataStream.write(flags, endianess: .littleEndian)
        
        /// Value (variable)
        if version >= .outlook2002 {
            UTF16String(value: value).write(to: &dataStream)
        } else {
            ASCIIString(value: value).write(to: &dataStream)
        }
    }
}
