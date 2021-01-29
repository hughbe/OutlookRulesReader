//
//  RulesHeader.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RulesHeader {
    public let version: OutlookRulesVersion
    public var signature: UInt32
    public var unknown1: UInt32
    public var unknown2: UInt32 = 0
    public var unknown3: UInt32 = 0
    public var unknown4: UInt32 = 0
    public var unknown5: UInt32 = 0
    public var unknown6: UInt32 = 0
    public var unknown7: UInt32 = 0
    public var unknown8: UInt32 = 1
    public var unknown9: UInt32 = 1
    public var unknown10: UInt32 = 0
    public var numberOfRules: UInt16
    
    public init(numberOfRules: UInt16) {
        self.version = .outlook2019
        self.signature = 0x00140000
        self.unknown1 = 0x06140000
        self.numberOfRules = numberOfRules
    }
    
    public init(dataStream: inout DataStream) throws {
        /// Signature (4 bytes)
        self.signature = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown1 (4 bytes)
        self.unknown1 = try dataStream.read(endianess: .littleEndian)

        switch self.signature {
        case 0x00140000: // Outlook 2019
            if self.unknown1 != 0x06140000 {
                throw OutlookRulesReadError.invalidSignature(signature: signature, unknown1: unknown1)
            }
            
            self.version = .outlook2019
        case 0x000F4240: // ??
            if self.unknown1 != 0x03140000 {
                throw OutlookRulesReadError.invalidSignature(signature: signature, unknown1: unknown1)
            }
            
            self.version = .outlook2019
        case 0x00124F80: // Outlook 2007
            if self.unknown1 != 0x06140000 {
                throw OutlookRulesReadError.invalidSignature(signature: signature, unknown1: unknown1)
            }
            
            self.version = .outlook2007
        case 0x0010C8E0: // Outlook 2003:
            if self.unknown1 != 0x04140000 {
                throw OutlookRulesReadError.invalidSignature(signature: signature, unknown1: unknown1)
            }
            
            self.version = .outlook2003
        case 0x000EF5BD: // Outlook 2002:
            guard self.unknown1 == 0x00000000 else {
                throw OutlookRulesReadError.corrupted
            }
            
            self.version = .outlook2002
        case 0x00000000: // Outlook 2002
            if self.unknown1 != 0x00000000 {
                throw OutlookRulesReadError.invalidSignature(signature: signature, unknown1: unknown1)
            }
            
            self.version = .noSignature
        default:
            throw OutlookRulesReadError.invalidSignature(signature: signature, unknown1: unknown1)
        }
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)

        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        self.unknown4 = try dataStream.read(endianess: .littleEndian)

        /// Unknown5 (4 bytes)
        self.unknown5 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown6 (4 bytes)
        self.unknown6 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown7 (4 bytes)
        if !self.version.shortHeaders {
            self.unknown7 = try dataStream.read(endianess: .littleEndian)
        }
        
        /// Unknown8 (4 bytes)
        self.unknown8 = try dataStream.read(endianess: .littleEndian)
        guard self.unknown8 == 1 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Unknown9 (4 bytes)
        self.unknown9 = try dataStream.read(endianess: .littleEndian)
        guard self.unknown9 == 1 else {
            throw OutlookRulesReadError.corrupted
        }
        
        /// Unknown10 (4 bytes)
        if !self.version.shortHeaders {
            self.unknown10 = try dataStream.read(endianess: .littleEndian)
        }
        
        /// Number of Rules (2 bytes)
        self.numberOfRules = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        /// Signature (4 bytes)
        dataStream.write(signature, endianess: .littleEndian)

        /// Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)
        
        /// Unknown5 (4 bytes)
        dataStream.write(unknown5, endianess: .littleEndian)
        
        /// Unknown6 (4 bytes)
        dataStream.write(unknown6, endianess: .littleEndian)
        
        /// Unknown7 (4 bytes)
        dataStream.write(unknown7, endianess: .littleEndian)
        
        /// Unknown8 (4 bytes)
        dataStream.write(unknown8, endianess: .littleEndian)
        
        /// Unknown9 (4 bytes)
        dataStream.write(unknown9, endianess: .littleEndian)
        
        /// Unknown10 (4 bytes)
        dataStream.write(unknown10, endianess: .littleEndian)
        
        /// Number of Rules (2 bytes)
        dataStream.write(numberOfRules, endianess: .littleEndian)
    }
}
