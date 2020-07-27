//
//  RulesHeader.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RulesHeader {
    public var signature: UInt32
    public var unknown1: UInt32
    public var unknown2: [UInt8] = [UInt8](repeating: 0, count: 24)
    public var unknown3: UInt32 = 1
    public var unknown4: UInt32 = 1
    public var unknown5: UInt32 = 0
    public var numberOfRules: UInt16
    
    public init(signature: UInt32 = 0x00140000, unknown1: UInt32 = 0x06140000, numberOfRules: UInt16) {
        self.signature = signature
        self.unknown1 = unknown1
        self.numberOfRules = numberOfRules
    }
    
    public init(dataStream: inout DataStream) throws {
        // Signature (4 bytes)
        signature = try dataStream.read(endianess: .littleEndian)
        
        // Unknown1 (4 bytes)
        unknown1 = try dataStream.read(endianess: .littleEndian)

        switch signature {
        case 0x00140000: // Outlook 2019
            if unknown1 != 0x06140000 {
                throw OutlookRulesFileError.invalidSignature(signature: signature, unknown1: unknown1)
            }
        case 0x000F4240: // ??
            if unknown1 != 0x03140000 {
                throw OutlookRulesFileError.invalidSignature(signature: signature, unknown1: unknown1)
            }
        case 0x00124F80: // Outlook 2007
            if unknown1 != 0x06140000 {
                throw OutlookRulesFileError.invalidSignature(signature: signature, unknown1: unknown1)
            }
        default:
            throw OutlookRulesFileError.invalidSignature(signature: signature, unknown1: unknown1)
        }

        // Unknown2 (24 bytes)
        unknown2 = try dataStream.readBytes(count: 24)
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)

        // Unknown4 (4 bytes)
        unknown4 = try dataStream.read(endianess: .littleEndian)

        // Unknown5 (4 bytes)
        unknown5 = try dataStream.read(endianess: .littleEndian)
        
        // Number of Rules (2 bytes)
        numberOfRules = try dataStream.read(endianess: .littleEndian)
        
        // Only seen one in each case
        if unknown3 != 1 || unknown4 != 1 {
            throw OutlookRulesFileError.corrupted
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Signature (4 bytes)
        dataStream.write(signature, endianess: .littleEndian)

        // Unknown1 (4 bytes)
        dataStream.write(unknown1, endianess: .littleEndian)
        
        // Unknown2 (24 bytes)
        dataStream.write(unknown2)
        
        // Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        
        // Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)
        
        // Unknown5 (4 bytes)
        dataStream.write(unknown5, endianess: .littleEndian)
        
        // Number of Rules (2 bytes)
        dataStream.write(numberOfRules, endianess: .littleEndian)
    }
}

