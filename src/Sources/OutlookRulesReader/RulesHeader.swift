//
//  RulesHeader.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RulesHeader {
    public let version: OutlookRulesVersion
    public var signature: UInt32?
    public var flags: UInt32?
    public var unknown1: UInt32? = 0
    public var unknown2: UInt32? = 0
    public var unknown3: UInt32? = 0
    public var unknown4: UInt32? = 0
    public var unknown5: UInt32? = 0
    public var unknown6: UInt32? = 0
    public var unknown7: UInt32? = 1
    public var unknown8: UInt32? = 1
    public var unknown9: UInt32? = 0
    public var numberOfRules: UInt16
    
    public init(numberOfRules: UInt16) {
        self.version = .outlook2019
        self.signature = 0x00140000
        self.flags = 0x06140000
        self.numberOfRules = numberOfRules
    }
    
    public init(dataStream: inout DataStream) throws {
        let peekedSignature: UInt32 = try dataStream.peek(endianess: .littleEndian)
        let version: OutlookRulesVersion
        switch peekedSignature {
        case 1310720:
            version = .outlook2019
        case 1200000:
            version = .outlook2007
        case 1100000:
            version = .outlook2003
        case 1000000:
            version = .outlook2002
        case 980413:
            version = .outlook2000
        case 970812:
            version = .outlook98
        case 0:
            version = .noSignatureOutlook2003
        default:
            version = .noSignature
        }
        
        self.version = version
        
        if version != .noSignatureOutlook2003 && version != .noSignature {
            /// Signature (4 bytes)
            let signature: UInt32 = try dataStream.read(endianess: .littleEndian)
            self.signature = signature
            
            /// Flags (4 bytes)
            if version >= .outlook2002 {
                let flags: UInt32 = try dataStream.read(endianess: .littleEndian)
                self.flags = flags
            
                guard (version == .outlook2019 && flags == 0x06140000) ||
                        (version == .outlook2007 && flags == 0x06140000) ||
                        (version == .outlook2007 && (flags == 0x06140000 || flags == 0x05124F80)) ||
                        (version == .outlook2003 && flags == 0x04140000) ||
                        (version == .outlook2002 && (flags == 0x03140000 || flags == 0x06140000 || flags == 0x03124F80 || flags == 0x05124F80)) else {
                    throw OutlookRulesReadError.invalidSignature(signature: signature, flags: flags)
                }
            } else {
                self.flags = nil
            }
        } else {
            self.signature = nil
            self.flags = nil
        }
        
        /// Unknown1 (4 bytes)
        if version != .noSignature {
            self.unknown1 = try dataStream.read(endianess: .littleEndian)
            guard self.unknown1 == 0x00000000 else {
                throw OutlookRulesReadError.corrupted
            }
        } else {
            self.unknown1 = nil
        }

        /// Unknown2 (4 bytes)
        if version != .noSignature {
            self.unknown2 = try dataStream.read(endianess: .littleEndian)
            guard self.unknown2 == 0x00000000 else {
                throw OutlookRulesReadError.corrupted
            }
        } else {
            self.unknown2 = nil
        }
        
        /// Unknown3 (4 bytes)
        if version != .noSignature {
            self.unknown3 = try dataStream.read(endianess: .littleEndian)
            guard self.unknown3 == 0x00000000 else {
                throw OutlookRulesReadError.corrupted
            }
        } else {
            self.unknown3 = nil
        }

        /// Unknown4 (4 bytes)
        if version != .noSignature {
            self.unknown4 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown4 = nil
        }
        
        /// Unknown5 (4 bytes)
        if version != .noSignature {
            self.unknown5 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown6 = nil
        }
        
        /// Unknown6 (4 bytes)
        if version != .noSignature {
            self.unknown6 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown6 = nil
        }

        /// Unknown7 (4 bytes)
        if version != .noSignature {
            self.unknown7 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown7 = nil
        }
        
        /// Unknown8 (4 bytes)
        if version != .noSignature {
            self.unknown8 = try dataStream.read(endianess: .littleEndian)
            guard self.unknown8 == 0x00000001 else {
                throw OutlookRulesReadError.corrupted
            }
        } else {
            self.unknown9 = nil
        }
        
        /// Unknown9 (4 bytes)
        if version >= .outlook2002 || version == .noSignatureOutlook2003 {
            self.unknown9 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown9 = nil
        }
        
        /// Number of Rules (2 bytes)
        self.numberOfRules = try dataStream.read(endianess: .littleEndian)
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        if let signature = signature {
            /// Signature (4 bytes)
            dataStream.write(signature, endianess: .littleEndian)
        }

        if let flags = flags {
            /// Flags (4 bytes)
            dataStream.write(flags, endianess: .littleEndian)
        }
        
        if let unknown1 = unknown1 {
            /// Unknown1 (4 bytes)
            dataStream.write(unknown1, endianess: .littleEndian)
        }
        
        if let unknown2 = unknown2 {
            /// Unknown2 (4 bytes)
            dataStream.write(unknown2, endianess: .littleEndian)
        }
        
        if let unknown3 = unknown3 {
            /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        }
        
        if let unknown4 = unknown4 {
            /// Unknown4 (4 bytes)
            dataStream.write(unknown4, endianess: .littleEndian)
        }
        
        if let unknown5 = unknown5 {
            /// Unknown5 (4 bytes)
            dataStream.write(unknown5, endianess: .littleEndian)
        }
        
        
        if let unknown6 = unknown6 {
            /// Unknown6 (4 bytes)
            dataStream.write(unknown6, endianess: .littleEndian)
        }
        
        if let unknown7 = unknown7 {
            /// Unknown7 (4 bytes)
            dataStream.write(unknown7, endianess: .littleEndian)
        }
        
        if let unknown8 = unknown8 {
            /// Unknown8 (4 bytes)
            dataStream.write(unknown8, endianess: .littleEndian)
        }
        
        /// Unknown9 (4 bytes)
        if let unknown9 = unknown9 {
            dataStream.write(unknown9, endianess: .littleEndian)
        }
        
        /// Number of Rules (2 bytes)
        dataStream.write(numberOfRules, endianess: .littleEndian)
    }
}
