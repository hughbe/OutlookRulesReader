//
//  RuleHeader.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct RuleHeader {
    public var signature: [UInt8]
    public var unknown1: UInt8 = 0
    public var name: String
    public var enabled: Bool
    public var unknown2: UInt32 = 0
    public var unknown3: UInt32 = 0
    public var unknown4: UInt32 = 0
    public var unknown5: UInt32 = 0
    public var dataSize: UInt32
    public var numberOfElements: UInt16
    
    public init(signature: [UInt8] = [0x00, 0x00, 0x14], name: String, enabled: Bool = false, numberOfElements: UInt16, dataSize: UInt32) {
        self.signature = signature
        self.name = name
        self.enabled = enabled
        self.dataSize = dataSize
        self.numberOfElements = numberOfElements
    }

    public init(dataStream: inout DataStream) throws {
        // Signature (3 bytes)
        signature = try dataStream.readBytes(count: 3)
        
        // Unknown1 (1 bytes)
        unknown1 = try dataStream.read()
        
        // Name (variable)
        name = try UTF16String(dataStream: &dataStream).value
        
        // Enabled (4 bytes)
        enabled = try dataStream.read(endianess: .littleEndian) as UInt32 != 0x0000
        
        // Unknown2 (4 bytes)
        unknown2 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown3 (4 bytes)
        unknown3 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown4 (4 bytes)
        unknown4 = try dataStream.read(endianess: .littleEndian)
        
        // Unknown5 (4 bytes)
        unknown5 = try dataStream.read(endianess: .littleEndian)
        
        // Data Size (4 bytes)
        dataSize = try dataStream.read(endianess: .littleEndian)
        
        // Rule Elements (2 bytes)
        numberOfElements = try dataStream.read(endianess: .littleEndian)
        
        // Separator (2 byte)
        let separator = try dataStream.read(endianess: .littleEndian) as UInt16
        switch separator {
        case 0xFFFF:
            // Unknown6 (2 bytes)
            let _ = try dataStream.read(endianess: .littleEndian) as UInt16
            
            // Class Name Length (2 bytes)
            let ruleClassLength = try dataStream.read(endianess: .littleEndian) as UInt16
            
            // Class Name (variable)
            guard let ruleClass = try dataStream.readString(count: Int(ruleClassLength), encoding: .ascii) else {
                throw OutlookRulesFileError.corrupted
            }

            if ruleClass != "CRuleElement" {
                throw OutlookRulesFileError.unknownRuleClass(ruleClass: ruleClass)
            }
        // Apparently this is known.
        case 0x8001:
            break
        default:
            throw OutlookRulesFileError.corrupted
        }
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Signature (3 bytes)
        dataStream.write(signature)
        
        // Unknown1 (1 byte)
        dataStream.write(unknown1)
        
        // Name (variable)
        UTF16String(value: name).write(to: &dataStream)
        
        // Enabled (4 bytes)
        dataStream.write((enabled ? 1 : 0) as UInt32, endianess: .littleEndian)
        
        // Unknown2 (4 bytes)
        dataStream.write(unknown2, endianess: .littleEndian)
        
        // Unknown3 (4 bytes)
        dataStream.write(unknown3, endianess: .littleEndian)
        
        // Unknown4 (4 bytes)
        dataStream.write(unknown4, endianess: .littleEndian)
        
        // Unknown5 (4 bytes)
        dataStream.write(unknown5, endianess: .littleEndian)
        
        // Data size (4 bytes)
        dataStream.write(dataSize, endianess: .littleEndian)
        
        // Number of Rule Elements (2 bytes)
        dataStream.write(numberOfElements, endianess: .littleEndian)
        
        // Separator (2 bytes)
        dataStream.write(0xFFFF as UInt16, endianess: .littleEndian)
        
        // Unknown2 (2 bytes)
        dataStream.write(0 as UInt16, endianess: .littleEndian)
        
        // Class Name Length (2 bytes)
        dataStream.write(0x000C as UInt16, endianess: .littleEndian)
        
        // Class Name (variable)
        dataStream.write("CRuleElement", encoding: .ascii)
    }
}
