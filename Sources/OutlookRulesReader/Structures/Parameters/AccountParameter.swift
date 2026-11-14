//
//  AccountParameter.swift
//
//
//  Created by Hugh Bellamy on 29/07/2020.
//

import DataStream

public struct AccountParameter: RuleParameter {
    public var reserved: UInt32 = 0
    public var accountName: String
    /// Probably an identifier of the account, written as a signed decimal 32-bit integer (spec §6.15).
    public var accountStamp: String
    
    public init(accountName: String, accountStamp: String) {
        self.accountName = accountName
        self.accountStamp = accountStamp
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)

        /// Account Name (variable)
        self.accountName = try VersionedString.read(from: &dataStream, version: version)
        
        /// Account Stamp (variable)
        self.accountStamp = try ASCIIString(dataStream: &dataStream).value
    }
    
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {        
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Account Name (variable)
        VersionedString.write(accountName, to: &dataStream, version: version)

        /// Account Stamp (variable)
        ASCIIString(value: accountStamp).write(to: &dataStream)
    }
}
