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

    /// Rule flags (spec §4.3.1, Unknown3). Usually 0; 0x20 has only been seen on the built-in junk e-mail
    /// "Exception List" rule. Not present in Outlook 97 files.
    public var flags: UInt32 = 0

    /// Fields of the rule header with unknown meaning, preserved when round-tripping (spec §4.3.1).
    internal var unknown1: UInt32 = 0
    internal var unknown2: UInt32 = 0
    internal var unknown4: UInt32 = 0
    
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
        /// The class descriptor for `CRuleElement` precedes the first element of the stream.
        var classDeclared = index != 0
        try self.init(dataStream: &dataStream, version: version, classDeclared: &classDeclared)
    }

    internal init(dataStream: inout DataStream, version: OutlookRulesVersion, classDeclared: inout Bool) throws {
        /// Header (variable)
        let header = try RuleHeader(dataStream: &dataStream, version: version)
        self.name = header.name
        self.enabled = header.enabled
        self.unknown1 = header.unknown1
        self.unknown2 = header.unknown2
        self.flags = header.unknown3 ?? 0
        self.unknown4 = header.unknown4 ?? 0
        
        /// Elements (variable)
        var elements: [RuleElement] = []
        elements.reserveCapacity(Int(header.numberOfElements))
        for _ in 0..<header.numberOfElements {
            /// Object Tag (2 bytes, or more for the first element of the stream)
            try ObjectTag.read(from: &dataStream, classDeclared: &classDeclared)

            /// Element (variable)
            elements.append(try RuleElement(dataStream: &dataStream, version: version))
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
        /// The class descriptor for `CRuleElement` precedes the first element of the stream.
        var classDeclared = index != 0
        write(to: &dataStream, version: version, classDeclared: &classDeclared)
    }

    internal func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion, classDeclared: inout Bool) {
        var elements: [RuleElement] = [
            // First element is rule condition
            RuleElement(identifier: .eventFlags, parameter: EventParameter(flags: self.eventFlags)),

            // Second element is unknown (0x0064).
            RuleElement(identifier: .unknown0x64, parameter: Unknown0x64Parameter())
        ]
        // The mandatory elements above are regenerated, so skip them here. All other elements
        // are written in their original order.
        elements.append(contentsOf: self.elements.filter { $0.identifier != .eventFlags && $0.identifier != .unknown0x64 })

        /// Elements (variable), each preceded by its object tag. These are written first so that the
        /// header's data size is measured rather than calculated.
        var elementsStream = OutputDataStream()
        for element in elements {
            /// Object Tag (2 bytes, or more for the first element of the stream)
            ObjectTag.write(to: &elementsStream, classDeclared: &classDeclared)
            
            /// Element (variable)
            element.write(to: &elementsStream, version: version)
        }

        /// Data Size counts the Number of Elements field (2 bytes) and everything after it.
        let dataSize = UInt32(2 + elementsStream.data.count)
        var header = RuleHeader(name: name, enabled: enabled, numberOfElements: UInt16(elements.count), dataSize: dataSize)
        header.unknown1 = unknown1
        header.unknown2 = unknown2
        header.unknown3 = flags
        header.unknown4 = unknown4
        header.write(to: &dataStream, version: version)
        
        dataStream.write(elementsStream.data)
    }
}
