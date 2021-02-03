//
//  PropertiesList.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import MAPI

internal struct PropertiesList {
    public var dataSize: UInt32 {
        var baseSize: UInt32 = 12
        for property in properties {
            baseSize += PropertyValueHeader.dataSize
            if let string = property.value as? String {
                // UTF-16 little-endian encoded string with null-terminator
                baseSize += UInt32(string.count + 1) * 2
            } else if let binary = property.value as? [UInt8] {
                baseSize += UInt32(binary.count)
            }
        }
        
        return baseSize
    }
    
    public var unknown: UInt32 = 0
    public let numberOfProperties: UInt32
    public let propertyBlockDataSize: UInt32

    public var properties: [UInt16: Any]
    
    public init(dataStream: inout DataStream) throws {
        /// Unknown (4 bytes)
        self.unknown = try dataStream.read(endianess: .littleEndian)
        
        /// Number of Properties (4 bytes)
        self.numberOfProperties = try dataStream.read(endianess: .littleEndian)
        
        /// Property Block Data Size (4 bytes)
        self.propertyBlockDataSize = try dataStream.read(endianess: .littleEndian)

        let startPosition = dataStream.position
        // let dataPosition = startPosition + Int(numberOfProperties * PropertyValueHeader.size)
        let endPosition = dataStream.position + Int(propertyBlockDataSize)
        
        var properties: [UInt16: Any] = [:]
        properties.reserveCapacity(Int(numberOfProperties))
        for _ in 0..<self.numberOfProperties {
            let header = try PropertyValueHeader(dataStream: &dataStream)
            let position = dataStream.position

            var value: Any
            switch header.tag.type {
            case PropertyType.integer32:
                value = UInt32(header.data2)
                break
            case PropertyType.errorCode:
                value = UInt32(header.data2)
                break
            case PropertyType.string:
                // Data stored in data block.
                let offset = Int(header.data2)
                guard offset >= 0 && offset <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }

                dataStream.position = startPosition + offset

                // Continue reading until null terminator.
                value = try dataStream.readUnicodeString(endianess: .littleEndian)!
                guard dataStream.position <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }
                
                dataStream.position = position
                break
            case PropertyType.binary:
                // Data stored in data block.
                let offset = Int(header.data2)
                guard offset >= 0 && offset <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }

                dataStream.position = startPosition + offset
                
                // Read length number of bytes.
                let length = Int(header.data3)
                guard length >= 0 && dataStream.position + length <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }
                
                value = try dataStream.readBytes(count: length)
                
                dataStream.position = position
                break
            default:
                fatalError("NYI: \(header.tag.type.stringRepresentation)")
            }
            
            properties[header.tag.id] = value
        }
        
        self.properties = properties
        dataStream.position = endPosition
    }
}
