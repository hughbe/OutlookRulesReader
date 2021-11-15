//
//  File.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct Rule: CustomDebugStringConvertible {
    public var name: String
    public var enabled: Bool
    public var eventFlags: RuleEventFlags
    
    public var elements: [RuleElement] = []
    
    public var conditions: [RuleElement] {
        elements.filter { $0.identifier.rawValue >= 200 && $0.identifier.rawValue < 300 }
    }
    public var actions: [RuleElement] {
        elements.filter { $0.identifier.rawValue >= 300 && $0.identifier.rawValue < 400 }
    }
    public var exceptions: [RuleElement] {
        elements.filter { $0.identifier.rawValue >= 500 && $0.identifier.rawValue < 600 }
    }

    public init(
        eventFlags: RuleEventFlags,
        name: String,
        enabled: Bool = true,
        conditions: [RuleElement] = [],
        actions: [RuleElement] = [],
        exceptions: [RuleElement] = []
    ) {
        self.eventFlags = eventFlags
        self.name = name
        self.enabled = enabled
        self.elements = conditions + actions + exceptions
    }
    
    public init(dataStream: inout DataStream, index: Int, version: OutlookRulesVersion) throws {
        /// Header (n bytes)
        let header = try RuleHeader(dataStream: &dataStream, index: index, version: version)
        self.name = header.name
        self.enabled = header.enabled
        
        /// Elements (variable)
        var elements: [RuleElement] = []
        elements.reserveCapacity(Int(header.numberOfElements))
        for i in 0..<header.numberOfElements {
            elements.append(try RuleElement(dataStream: &dataStream, version: version))

            /// Separator (2 bytes)
            if i != header.numberOfElements - 1 {
                let separator = try dataStream.read(endianess: .littleEndian) as UInt16
                if separator != 0x8001 {
                    throw OutlookRulesReadError.invalidSeparator(separator: separator)
                }
            }
        }
        
        self.elements = elements
        
        guard let eventElement = elements.first(where: { $0.identifier == .eventFlags }),
              let eventParameter = eventElement.parameter as? EventParameter else {
            throw OutlookRulesReadError.corrupted
        }
        
        self.eventFlags = eventParameter.flags
    }

    public var debugDescription: String {
        var s = ""
        s += "Name: \(name)"
        return s
    }
    
    public func write(to dataStream: inout OutputDataStream, index: Int, version: OutlookRulesVersion) {
        var elements: [RuleElement] = [
            // First element is rule condition
            RuleElement(identifier: .eventFlags, parameter: EventParameter(flags: self.eventFlags)),

            // Second element is unknown (0x0064).
            RuleElement(identifier: .unknown0x64, parameter: Unknown0x64Parameter())
        ]
        elements.append(contentsOf: conditions)
        elements.append(contentsOf: actions)
        elements.append(contentsOf: exceptions)

        let numberOfElements = UInt16(elements.count)
        let separatorDataSize = UInt32(2 * (elements.count - 1))
        
        /// Number of Rule Elements (2 bytes)
        /// Separator (2 bytes)
        /// Padding (2 bytes)
        /// Class Name Length (2 bytes)
        /// Class Name (12 bytes - CRuleElement)
        let remainingLength: UInt32 = 2 + 2 + 2 + 2 + 12
        let dataSize = elements.map { $0.dataSize }.reduce(0, +) + separatorDataSize + remainingLength

        let header = RuleHeader(name: name, enabled: enabled, numberOfElements: numberOfElements, dataSize: dataSize)
        header.write(to: &dataStream, index: index)

        for (i, element) in elements.enumerated() {
            /// Element (variable)
            element.write(to: &dataStream, version: version)
            
            if i != elements.count - 1 {
                /// Separator (2 bytes)
                dataStream.write(0x8001 as UInt16, endianess: .littleEndian)
            }
        }
    }
}
