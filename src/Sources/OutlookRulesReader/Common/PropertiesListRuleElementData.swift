//
//  PropertiesList.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

internal struct PropertyValueHeader {
    public static var dataSize: UInt32 = 16
    
    public var id: UInt16
    public var dataType: UInt16
    public var data1: UInt32
    public var data2: UInt32
    public var data3: UInt32
    
    public init(dataStream: inout DataStream) throws {
        // Data Type (2 bytes)
        dataType = try dataStream.read(endianess: .littleEndian)

        // Id (2 bytes)
        id = try dataStream.read(endianess: .littleEndian)

        // Data 1 (4 bytes)
        data1 = try dataStream.read(endianess: .littleEndian)
        
        // Data 2 (4 bytes)
        data2 = try dataStream.read(endianess: .littleEndian)
        
        // Data 3 (4 bytes)
        data3 = try dataStream.read(endianess: .littleEndian)
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
        for _ in 1...numberOfProperties {
            let header = try PropertyValueHeader(dataStream: &dataStream)
            let position = dataStream.position

            var value: Any
            switch header.dataType {
            case PropertyDataType.integer32.rawValue:
                // Data stored inline.
                value = Int(header.data2)
                break
            case PropertyDataType.errorCode.rawValue:
                value = Int(header.data2)
                break
            case PropertyDataType.string.rawValue:
                // Data stored in data block.
                let offset = Int(header.data2)
                assert(offset >= 0 && offset < endPosition)
                dataStream.position = startPosition + offset

                // Continue reading until null terminator.
                value = try dataStream.readUTF16LEString() as Any
                assert(dataStream.position <= endPosition, "Can't read binary data beyond the length of the data stream")
                
                dataStream.position = position
                break
            case PropertyDataType.binary.rawValue:
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
                fatalError("Unknown data type \(header.dataType.hexString)")
            }
            
            properties[header.id] = value
        }

        dataStream.position = endPosition
    }
}
