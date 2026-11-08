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
    
    public init(numberOfRules: UInt16, version: OutlookRulesVersion = .outlook2019) {
        self.version = version
        self.signature = RulesHeader.defaultSignature(for: version)
        self.flags = RulesHeader.defaultFlags(for: version)
        self.numberOfRules = numberOfRules
    }
    
    static func defaultSignature(for version: OutlookRulesVersion) -> UInt32? {
        switch version {
        case .outlook2019: return 1310720
        case .outlook2007: return 1200000
        case .outlook2003: return 1100000
        case .outlook2002: return 1000000
        case .outlook2000: return 980413
        case .outlook98: return 970812
        case .noSignatureOutlook2003, .noSignature: return nil
        }
    }
    
    private static func defaultFlags(for version: OutlookRulesVersion) -> UInt32? {
        switch version {
        case .outlook2019, .outlook2007: return 0x06140000
        case .outlook2003: return 0x04140000
        case .outlook2002: return 0x03140000
        case .outlook2000, .outlook98, .noSignatureOutlook2003, .noSignature: return nil
        }
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
            self.unknown5 = nil
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
            self.unknown8 = nil
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
    
    /// Writes the header in the layout of the specified version.
    /// Fields that were read from a file of the same version are preserved; fields that are
    /// not present in this header (e.g. when converting between versions) use sensible defaults.
    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        let source = version == self.version ? self : RulesHeader(numberOfRules: numberOfRules, version: version)

        if version >= .outlook98 {
            /// Signature (4 bytes)
            dataStream.write(source.signature ?? RulesHeader.defaultSignature(for: version) ?? 0, endianess: .littleEndian)
        }

        if version >= .outlook2002 {
            /// Flags (4 bytes)
            dataStream.write(source.flags ?? RulesHeader.defaultFlags(for: version) ?? 0, endianess: .littleEndian)
        }
        
        if version != .noSignature {
            /// Unknown1 (4 bytes)
            dataStream.write(source.unknown1 ?? 0, endianess: .littleEndian)
            
            /// Unknown2 (4 bytes)
            dataStream.write(source.unknown2 ?? 0, endianess: .littleEndian)
            
            /// Unknown3 (4 bytes)
            dataStream.write(source.unknown3 ?? 0, endianess: .littleEndian)
            
            /// Unknown4 (4 bytes)
            dataStream.write(source.unknown4 ?? 0, endianess: .littleEndian)
            
            /// Unknown5 (4 bytes)
            dataStream.write(source.unknown5 ?? 0, endianess: .littleEndian)
            
            /// Unknown6 (4 bytes)
            dataStream.write(source.unknown6 ?? 0, endianess: .littleEndian)
            
            /// Unknown7 (4 bytes)
            dataStream.write(source.unknown7 ?? 1, endianess: .littleEndian)
            
            /// Unknown8 (4 bytes)
            dataStream.write(source.unknown8 ?? 1, endianess: .littleEndian)
        }
        
        if version >= .outlook2002 || version == .noSignatureOutlook2003 {
            /// Unknown9 (4 bytes)
            dataStream.write(source.unknown9 ?? 0, endianess: .littleEndian)
        }
        
        /// Number of Rules (2 bytes)
        dataStream.write(numberOfRules, endianess: .littleEndian)
    }
}
