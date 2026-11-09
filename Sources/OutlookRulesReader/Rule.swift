//
//  Rule.swift
//
//
//  Created by Hugh Bellamy on 28/07/2020.
//

import DataStream

public struct Rule: CustomDebugStringConvertible {
    /// The rule's name, without the template name.
    public var name: String

    /// The name of the Rules Wizard template the rule was created from, such as "Build as I go".
    /// Outlook 97 stores it after the rule name, separated by a tab (spec §4.3.1); nil if the stored name has no tab.
    public var templateName: String?

    public var enabled: Bool

    /// When the rule runs: the parameter of the mandatory 0x0190 element.
    public var eventFlags: RuleEventFlags

    /// The kinds of item the rule applies to: the parameter of the mandatory 0x0064 "For each <message>" element.
    public var itemTypes: RuleItemTypes = .message

    /// Whether the rule has been saved to the Exchange server's rules table (spec §4.3.1).
    public var isServerRule: Bool = false

    /// Rule flags (spec §4.3.1). Usually 0. 0x20 has only been seen on the built-in junk e-mail "Exception List"
    /// rule; Outlook 98 clears the flags when the user edits a rule with bit 0x1 or 0x2 set. Added in version
    /// 970812 (Outlook 98), so not present in Outlook 97 or signature-0 files.
    public var flags: UInt32 = 0

    /// All of the rule's elements, including the mandatory 0x0190 and 0x0064 elements.
    /// When the rule is written, those two are regenerated from `eventFlags` and `itemTypes`.
    public var elements: [RuleElement] = []

    /// Fields of the rule header with unknown meaning, preserved when round-tripping (spec §4.3.1).
    /// Outlook 97 never reads Unknown1; it only copies and saves it.
    internal var unknown1: UInt32 = 0
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
        templateName: String? = nil,
        enabled: Bool = true,
        itemTypes: RuleItemTypes = .message,
        conditions: [RuleElement] = [],
        actions: [RuleElement] = [],
        exceptions: [RuleElement] = []
    ) {
        self.eventFlags = eventFlags
        self.name = name
        self.templateName = templateName
        self.enabled = enabled
        self.itemTypes = itemTypes
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
        (self.name, self.templateName) = Rule.splitName(header.name)
        self.enabled = header.enabled
        self.unknown1 = header.unknown1
        self.isServerRule = header.serverRule != 0
        self.flags = header.flags ?? 0
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

        if let itemTypeParameter = elements.first(where: { $0.identifier == .itemType })?.parameter as? ItemTypeParameter {
            self.itemTypes = itemTypeParameter.itemTypes
        }
    }

    /// Splits a stored name into the rule name and the template name (spec §4.3.1).
    private static func splitName(_ storedName: String) -> (String, String?) {
        guard let tab = storedName.firstIndex(of: "\t") else {
            return (storedName, nil)
        }

        return (String(storedName[..<tab]), String(storedName[storedName.index(after: tab)...]))
    }

    /// The name as stored in the file: the rule name, followed by a tab and the template name if there is one.
    public var storedName: String {
        guard let templateName = templateName else {
            return name
        }

        return name + "\t" + templateName
    }

    public var debugDescription: String {
        var s = ""
        s += "Name: \(name)"
        if let templateName = templateName {
            s += "\tTemplate: \(templateName)"
        }
        return s
    }

    public func write(to dataStream: inout OutputDataStream, index: Int, version: OutlookRulesVersion) {
        /// The class descriptor for `CRuleElement` precedes the first element of the stream.
        var classDeclared = index != 0
        write(to: &dataStream, version: version, versionStamp: nil, classDeclared: &classDeclared)
    }

    /// `versionStamp` is the stream's version stamp, which each rule header repeats in the Outlook 2002 and later
    /// formats; nil uses the default stamp for `version`.
    internal func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion, versionStamp: UInt32?, classDeclared: inout Bool) {
        var elements: [RuleElement] = [
            /// "Apply this rule <after the message arrives>"
            RuleElement(identifier: .eventFlags, parameter: EventParameter(flags: eventFlags)),

            /// "For each <message>"
            RuleElement(identifier: .itemType, parameter: ItemTypeParameter(itemTypes: itemTypes))
        ]
        // The mandatory elements above are regenerated, so skip them here. All other elements
        // are written in their original order.
        elements.append(contentsOf: self.elements.filter { $0.identifier != .eventFlags && $0.identifier != .itemType })

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
        var header = RuleHeader(name: storedName, enabled: enabled, numberOfElements: UInt16(elements.count), dataSize: dataSize)
        header.versionStamp = versionStamp
        header.unknown1 = unknown1
        header.serverRule = isServerRule ? 1 : 0
        header.flags = flags
        header.unknown4 = unknown4
        header.write(to: &dataStream, version: version)

        dataStream.write(elementsStream.data)
    }
}
