//
//  AccountParameter.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream

public struct AccountParameter: RuleParameter {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 4
        baseSize += UTF16String(value: accountName).dataSize
        baseSize += ASCIIString(value: accountName).dataSize
        return baseSize
    }

    public var reserved: UInt32 = 0
    public var accountName: String
    public var unknown: String
    
    public init(accountName: String, unknown: String) {
        self.accountName = accountName
        self.unknown = unknown
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Account Name (variable)
        self.accountName = try UTF16String(dataStream: &dataStream).value
        
        /// Unknown (variable)
        self.unknown = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Account Name (variable)
        UTF16String(value: accountName).write(to: &dataStream)

        /// Unknown (variable)
        ASCIIString(value: unknown).write(to: &dataStream)
    }
}
