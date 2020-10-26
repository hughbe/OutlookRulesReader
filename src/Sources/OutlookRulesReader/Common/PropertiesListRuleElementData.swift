//
//  PropertiesList.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream
import MAPI

internal struct PropertyValueHeader {
    public static var dataSize: UInt32 = 16
    
    public var tag: PropertyTag
    public var data1: UInt32
    public var data2: UInt32
    public var data3: UInt32
    
    public init(dataStream: inout DataStream) throws {
        // Tag (4 bytes)
        self.tag = try PropertyTag(dataStream: &dataStream)

        // Data 1 (4 bytes)
        self.data1 = try dataStream.read(endianess: .littleEndian)
        
        // Data 2 (4 bytes)
        self.data2 = try dataStream.read(endianess: .littleEndian)
        
        // Data 3 (4 bytes)
        self.data3 = try dataStream.read(endianess: .littleEndian)
    }
}

internal struct PropertiesList {
    public var unknown: UInt32 = 0
    public let numberOfProperties: UInt32
    public let propertyBlockDataSize: UInt32

    public var properties: [UInt16: Any]
    
    public init(dataStream: inout DataStream) throws {
        // Unknown (4 bytes)
        unknown = try dataStream.read(endianess: .littleEndian)
        
        // Number of Properties (4 bytes)
        numberOfProperties = try dataStream.read(endianess: .littleEndian)
        
        // Property Block Data Size (4 bytes)
        propertyBlockDataSize = try dataStream.read(endianess: .littleEndian)

        let startPosition = dataStream.position
        // let dataPosition = startPosition + Int(numberOfProperties * PropertyValueHeader.size)
        let endPosition = dataStream.position + Int(propertyBlockDataSize)
        
        properties = [:]
        properties.reserveCapacity(Int(numberOfProperties))
        for _ in 0..<numberOfProperties {
            let header = try PropertyValueHeader(dataStream: &dataStream)
            let position = dataStream.position

            var value: Any
            switch header.tag.type {
            case PropertyType.integer32:
                // Data stored inline.
                value = Int(header.data2)
                break
            case PropertyType.errorCode:
                value = Int(header.data2)
                break
            case PropertyType.string:
                // Data stored in data block.
                let offset = Int(header.data2)
                assert(offset >= 0 && offset < endPosition)
                dataStream.position = startPosition + offset

                // Continue reading until null terminator.
                value = try dataStream.readUnicodeString(endianess: .littleEndian)!
                assert(dataStream.position <= endPosition, "Can't read binary data beyond the length of the data stream")
                
                dataStream.position = position
                break
            case PropertyType.binary:
                // Data stored in data block.
                let offset = Int(header.data2)
                assert(offset >= 0 && offset < endPosition)
                dataStream.position = startPosition + offset
                
                // Read length number of bytes.
                let length = Int(header.data3)
                assert(length >= 0 && dataStream.position + length <= endPosition, "Can't read binary data beyond the length of the data stream")
                value = try dataStream.readBytes(count: length)
                
                dataStream.position = position
                break
            default:
                fatalError("NYI: \(header.tag.type.stringRepresentation)")
            }
            
            properties[header.tag.id] = value
        }

        dataStream.position = endPosition
    }
}
