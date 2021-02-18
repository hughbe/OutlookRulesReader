//
//  RuleHeader.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RuleHeader {
    public var signature: UInt32?
    public var name: String
    public var enabled: Bool
    public var unknown2: UInt32 = 0
    public var unknown3: UInt32 = 0
    public var unknown4: UInt32? = 0
    public var unknown5: UInt32? = 0
    public var dataSize: UInt32?
    public var numberOfElements: UInt16
    
    public init(signature: UInt32 = 0x00140000, name: String, enabled: Bool = false, numberOfElements: UInt16, dataSize: UInt32) {
        self.signature = signature
        self.name = name
        self.enabled = enabled
        self.dataSize = dataSize
        self.numberOfElements = numberOfElements
    }

    public init(dataStream: inout DataStream, index: Int, version: OutlookRulesVersion) throws {
        if version >= .outlook2002 {
            /// Signature (4 bytes)
            self.signature = try dataStream.read(endianess: .littleEndian)
        } else {
            self.signature = nil
        }
        
        /// Name (variable)
        if version != .noSignatureOutlook2003 && version >= .outlook2002 {
            self.name = try UTF16String(dataStream: &dataStream).value
        } else {
            self.name = try ASCIIString(dataStream: &dataStream).value
        }
        
        /// Enabled (4 bytes)
        self.enabled = try dataStream.read(endianess: .littleEndian) as UInt32 != 0x0000
        
        /// Unknown2 (4 bytes)
        self.unknown2 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown3 (4 bytes)
        self.unknown3 = try dataStream.read(endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        if version >= .outlook98 {
            self.unknown4 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown4 = nil
        }
        
        /// Unknown5 (4 bytes)
        if version >= .outlook2002 {
            self.unknown5 = try dataStream.read(endianess: .littleEndian)
        } else {
            self.unknown5 = nil
        }
        
        /// Data Size (4 bytes)
        if version >= .outlook2002 {
            self.dataSize = try dataStream.read(endianess: .littleEndian)
        } else {
            self.dataSize = nil
        }
        
        /// Rule Elements (2 bytes)
        self.numberOfElements = try dataStream.read(endianess: .littleEndian)
        
        /// Separator (2 byte)
        /// The first rule element contains 0xFFFF followed by a class name ("CRuleElement").
        /// Subsequent rule elements contain the separator 0x8001.
        let separator: UInt16 = try dataStream.read(endianess: .littleEndian)
        switch separator {
        case 0xFFFF:
            guard index == 0 else {
                throw OutlookRulesReadError.corrupted
            }
            
            /// Padding (2 bytes)
            let _: UInt16 = try dataStream.read(endianess: .littleEndian)
            
            /// Class Name Length (2 bytes)
            let ruleClassLength: UInt16 = try dataStream.read(endianess: .littleEndian)
            guard ruleClassLength == 12 && ruleClassLength <= dataStream.remainingCount else {
                throw OutlookRulesReadError.corrupted
            }
            
            /// Class Name (variable)
            guard let ruleClass = try dataStream.readString(count: Int(ruleClassLength), encoding: .ascii) else {
                throw OutlookRulesReadError.corrupted
            }

            guard ruleClass == "CRuleElement" else {
                throw OutlookRulesReadError.unknownRuleClass(ruleClass: ruleClass)
            }
        case 0x8001:
            guard index != 0 else {
                throw OutlookRulesReadError.corrupted
            }

            break
        default:
            throw OutlookRulesReadError.corrupted
        }
    }
    
    public func write(to dataStream: inout OutputDataStream, index: Int) {
        if let signature = signature {
            /// Signature (4 bytes)
            dataStream.write(signature, endianess: .littleEndian)
        }
        
        /// Name (variable)
        UTF16String(value: name).write(to: &dataStream)
        
        /// Enabled (4 bytes)
        dataStream.write((enabled ? 1 : 0) as UInt32, endianess: .littleEndian)
        
        /// Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        /// Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        
        /// Unknown4 (4 bytes)
        if let unknown4 = unknown4 {
            dataStream.write(unknown4, endianess: .littleEndian)
        }
        
        /// Unknown5 (4 bytes)
        if let unknown5 = unknown5 {
            dataStream.write(unknown5, endianess: .littleEndian)
        }
        
        /// Data size (4 bytes)
        if let dataSize = dataSize {
            dataStream.write(dataSize, endianess: .littleEndian)
        }
        
        /// Number of Rule Elements (2 bytes)
        dataStream.write(numberOfElements, endianess: .littleEndian)
        
        if index == 0 {
            /// Separator (2 bytes)
            dataStream.write(0xFFFF as UInt16, endianess: .littleEndian)
            
            /// Unknown2 (2 bytes)
            dataStream.write(0 as UInt16, endianess: .littleEndian)
            
            /// Class Name Length (2 bytes)
            dataStream.write(0x000C as UInt16, endianess: .littleEndian)
            
            /// Class Name (variable)
            dataStream.write("CRuleElement", encoding: .ascii)
        } else {
            /// Separator (2 bytes)
            dataStream.write(0x8001 as UInt16, endianess: .littleEndian)
        }
    }
}
