//
//  AdrEntry.swift
//  
//
//  Created by Hugh Bellamy on 03/02/2021.
//

import DataStream
import Foundation
import MAPI

/// A serialized MAPI `ADRENTRY` whose `SPropValue` array has its pointers replaced by offsets (spec §6.4).
internal struct AdrEntry {
    /// A single property, retaining everything needed to write it back byte-for-byte.
    public struct Property {
        public var type: PropertyType
        public var id: UInt16
        public var alignPad: UInt32
        public var valueHigh: UInt32
        public var value: Any
        
        /// Whether the value is of the Swift type that is used to represent the property type.
        public func accepts(_ value: Any) -> Bool {
            switch type {
            case .integer32, .errorCode:
                return value is UInt32
            case .string, .string8:
                return value is String
            case .binary:
                return value is [UInt8]
            case .boolean:
                return value is Bool
            default:
                return false
            }
        }
        
        /// Infers the property type to use for a value that has no recorded type.
        public static func inferredType(for value: Any) -> PropertyType? {
            switch value {
            case let value as UInt32:
                // Error codes (e.g. MAPI_E_NOT_FOUND) have the high bit set.
                return value >= 0x80000000 ? .errorCode : .integer32
            case is String:
                return .string
            case is [UInt8]:
                return .binary
            case is Bool:
                return .boolean
            default:
                return nil
            }
        }
    }
    
    public var dataSize: UInt32 {
        var stream = OutputDataStream()
        write(to: &stream)
        return UInt32(stream.data.count)
    }
    
    /// `ADRENTRY.ulReserved1`. Often uninitialised memory; preserved when round-tripping.
    public var reserved1: UInt32 = 0
    public var propertyValues: [Property]

    /// The values of the properties, keyed by property ID.
    public var properties: [UInt16: Any] {
        var properties: [UInt16: Any] = [:]
        properties.reserveCapacity(propertyValues.count)
        for entry in propertyValues {
            properties[entry.id] = entry.value
        }
        
        return properties
    }
    
    public init(propertyValues: [Property], reserved1: UInt32 = 0) {
        self.propertyValues = propertyValues
        self.reserved1 = reserved1
    }
    
    /// Creates a list from property values, reusing the types, order and flags of the properties
    /// in a previous list, if there is one, so that unmodified properties are written back unchanged.
    public init(properties: [UInt16: Any], reusing previous: AdrEntry? = nil) {
        var remaining = properties
        var propertyValues: [Property] = []
        propertyValues.reserveCapacity(properties.count)
        if let previous = previous {
            for var entry in previous.propertyValues {
                guard let value = remaining[entry.id], entry.accepts(value) else {
                    continue
                }
                
                entry.value = value
                propertyValues.append(entry)
                remaining[entry.id] = nil
            }
        }
        
        for id in remaining.keys.sorted() {
            let value = remaining[id]!
            guard let type = Property.inferredType(for: value) else {
                continue
            }
            
            propertyValues.append(Property(type: type, id: id, alignPad: 0, valueHigh: 0, value: value))
        }
        
        self.init(propertyValues: propertyValues, reserved1: previous?.reserved1 ?? 0)
    }
    
    public init(dataStream: inout DataStream) throws {
        /// Reserved1 (4 bytes)
        self.reserved1 = try dataStream.read(endianess: .littleEndian)
        
        /// Number of Properties (4 bytes)
        let numberOfProperties: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Block Size (4 bytes): the size of the SPropValue array and the data it points to, as produced by MAPI ScCopyProps (spec §6.4)
        let propertyBlockDataSize: UInt32 = try dataStream.read(endianess: .littleEndian)

        let startPosition = dataStream.position
        let endPosition = dataStream.position + Int(propertyBlockDataSize)
        
        var propertyValues: [Property] = []
        propertyValues.reserveCapacity(Int(numberOfProperties))
        for _ in 0..<numberOfProperties {
            let header = try SPropValue(dataStream: &dataStream)
            let position = dataStream.position

            var value: Any
            switch header.tag.type {
            case PropertyType.integer32:
                value = UInt32(header.valueLow)
                break
            case PropertyType.errorCode:
                value = UInt32(header.valueLow)
                break
            case PropertyType.string:
                // Data stored in data block.
                let offset = Int(header.valueLow)
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
            case PropertyType.string8:
                // Data stored in data block.
                let offset = Int(header.valueLow)
                guard offset >= 0 && offset <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }

                dataStream.position = startPosition + offset

                // Continue reading until null terminator.
                value = try dataStream.readAsciiString()!
                guard dataStream.position <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }
                
                dataStream.position = position
                break
            case PropertyType.binary:
                // Data stored in data block. Like an SBinary, the value is a length followed by the location of the data.
                let length = Int(header.valueLow)
                let offset = Int(header.valueHigh)
                guard offset >= 0 && offset <= endPosition - startPosition else {
                    throw OutlookRulesReadError.corrupted
                }

                dataStream.position = startPosition + offset
                
                guard length >= 0 && dataStream.position + length <= endPosition else {
                    throw OutlookRulesReadError.corrupted
                }
                
                value = try dataStream.readBytes(count: length)
                
                dataStream.position = position
                break
            case PropertyType.boolean:
                value = UInt16(truncatingIfNeeded: header.valueLow) != 0
            default:
                // Property type not yet supported.
                throw OutlookRulesReadError.corrupted
            }
            
            propertyValues.append(Property(type: header.tag.type, id: header.tag.id, alignPad: header.alignPad, valueHigh: header.valueHigh, value: value))
        }
        
        self.propertyValues = propertyValues
        dataStream.position = endPosition
    }
    
    public func write(to dataStream: inout OutputDataStream) {
        // Property headers are followed by a data block that holds strings and binary values.
        var dataBlock = OutputDataStream()
        var headers: [(type: PropertyType, id: UInt16, alignPad: UInt32, valueLow: UInt32, valueHigh: UInt32)] = []
        headers.reserveCapacity(propertyValues.count)
        let dataBlockOffset = propertyValues.count * Int(SPropValue.dataSize)
        
        for entry in propertyValues {
            var valueLow: UInt32 = 0
            var valueHigh = entry.valueHigh
            switch entry.type {
            case .integer32, .errorCode:
                valueLow = (entry.value as? UInt32) ?? 0
            case .boolean:
                valueLow = ((entry.value as? Bool) ?? false) ? 1 : 0
            case .string:
                valueLow = UInt32(dataBlockOffset + dataBlock.data.count)
                dataBlock.write((entry.value as? String) ?? "", encoding: .utf16LittleEndian)
                dataBlock.write(0 as UInt16, endianess: .littleEndian)
            case .string8:
                valueLow = UInt32(dataBlockOffset + dataBlock.data.count)
                let bytes = ((entry.value as? String) ?? "").data(using: .isoLatin1, allowLossyConversion: true) ?? Data()
                dataBlock.write(bytes)
                dataBlock.write(0 as UInt8)
            case .binary:
                let bytes = (entry.value as? [UInt8]) ?? []
                valueLow = UInt32(bytes.count)
                valueHigh = UInt32(dataBlockOffset + dataBlock.data.count)
                dataBlock.write(Data(bytes))
            default:
                break
            }
            
            headers.append((entry.type, entry.id, entry.alignPad, valueLow, valueHigh))
        }
        
        /// Reserved1 (4 bytes)
        dataStream.write(reserved1, endianess: .littleEndian)
        
        /// Number of Properties (4 bytes)
        dataStream.write(UInt32(propertyValues.count), endianess: .littleEndian)
        
        /// Block Size (4 bytes): the size of the SPropValue array and the data it points to, as produced by MAPI ScCopyProps (spec §6.4)
        dataStream.write(UInt32(dataBlockOffset + dataBlock.data.count), endianess: .littleEndian)
        
        /// Property Headers (variable)
        for header in headers {
            dataStream.write(header.type.rawValue, endianess: .littleEndian)
            dataStream.write(header.id, endianess: .littleEndian)
            dataStream.write(header.alignPad, endianess: .littleEndian)
            dataStream.write(header.valueLow, endianess: .littleEndian)
            dataStream.write(header.valueHigh, endianess: .littleEndian)
        }
        
        /// Data Block (variable)
        dataStream.write(dataBlock.data)
    }
}
