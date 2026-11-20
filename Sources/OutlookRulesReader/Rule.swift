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

    /// Rule flags (spec §4.3.1.1). Empty for rules the user creates; Outlook 2000 uses them to mark the rules
    /// its junk-mail feature creates. Added in version 970812 (Outlook 98), so not stored in Outlook 97 or
    /// signature-0 files.
    public var flags: RuleFlags = []

    /// All of the rule's elements, including the mandatory 0x0190 and 0x0064 elements.
    /// When the rule is written, those two are regenerated from `eventFlags` and `itemTypes`.
    public var elements: [RuleElement] = []

    /// Whether the rule failed while Outlook was running it on the client (RuleHeader RunError, spec §4.3.1).
    /// Outlook 2000 and later set it to 1, and disable the rule, when one of the rule's actions fails; Outlook 98
    /// stores the failing action's HRESULT instead, so any non-zero value means an error.
    public var hasRunError: Bool {
        get { runError != 0 }
        set { runError = newValue ? 1 : 0 }
    }

    /// The raw RunError field, preserved when round-tripping.
    internal var runError: UInt32 = 0

    /// The ID Outlook gave the rule's copy on the Exchange server (RuleHeader ServerRuleId, Outlook 2002 and later;
    /// spec §4.3.1). 0 if the rule has never been saved to the server. Not stored in older formats.
    public var serverRuleId: UInt32 = 0

    /// The rule's own version stamp and the format it was read from, so that a rule whose stamp differs from the
    /// stream's keeps it when written back in the same format (spec §4.3.1).
    internal var versionStamp: UInt32?
    internal var sourceVersion: OutlookRulesVersion?

    /// False for a rule read with DataSize 0, which stores no element list (spec §4.3.1). Such a rule is written
    /// back the same way in the Outlook 2002 and later formats while it still has no elements.
    internal var hasElementList: Bool = true

    /// The oldest format that can store the rule: the newest `minimumVersion` of its elements (spec §5.5).
    public var minimumVersion: OutlookRulesVersion {
        elements.map { $0.identifier.minimumVersion }.max() ?? .outlook97
    }

    /// Whether a file in the format of `version` can store every element of the rule (spec §5.5).
    public func isSupported(in version: OutlookRulesVersion) -> Bool {
        elements.allSatisfy { $0.identifier.isSupported(in: version) }
    }

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

    /// Reads a single rule. `index` stands in for whether an earlier rule in the stream already declared the
    /// `CRuleElement` class, which is wrong when an earlier rule had no elements (spec §2.5).
    @available(*, deprecated, message: "Read the whole stream with OutlookRules(data:), which tracks the class declaration.")
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
        self.runError = header.runError
        self.isServerRule = header.serverRule != 0
        self.flags = RuleFlags(rawValue: header.flags ?? 0)
        self.serverRuleId = header.serverRuleId ?? 0
        self.versionStamp = header.versionStamp
        self.sourceVersion = version
        let contentVersion = RuleHeader.contentVersion(streamVersion: version, versionStamp: header.versionStamp)

        /// Data Size counts the Number of Elements field (2 bytes), which the header has already read, and everything
        /// after it (spec §4.3.1). Outlook writes it exactly, so a rule whose elements end anywhere else was misread.
        let elementsStart = dataStream.position
        if let dataSize = header.dataSize, header.hasElementList {
            guard dataSize >= 2, Int(dataSize - 2) <= dataStream.remainingCount else {
                throw OutlookRulesReadError.corrupted
            }
        }

        /// Elements (variable)
        var elements: [RuleElement] = []
        elements.reserveCapacity(Int(header.numberOfElements))
        for _ in 0..<header.numberOfElements {
            /// Object Tag (2 bytes, or more for the first element of the stream)
            try ObjectTag.read(from: &dataStream, classDeclared: &classDeclared)

            /// Element (variable)
            elements.append(try RuleElement(dataStream: &dataStream, version: contentVersion))
        }

        if let dataSize = header.dataSize, header.hasElementList {
            guard dataStream.position - elementsStart == Int(dataSize - 2) else {
                throw OutlookRulesReadError.corrupted
            }
        }

        self.elements = elements
        self.hasElementList = header.hasElementList

        if !header.hasElementList {
            /// Outlook 2003 stores the Download Options rule without elements (spec §4.3.1).
            self.eventFlags = []
            return
        }

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

    /// Writes a single rule. See `init(dataStream:index:version:)` for why `index` can be wrong.
    @available(*, deprecated, message: "Write the whole stream with OutlookRules.getData(version:), which tracks the class declaration.")
    public func write(to dataStream: inout OutputDataStream, index: Int, version: OutlookRulesVersion) {
        /// The class descriptor for `CRuleElement` precedes the first element of the stream.
        var classDeclared = index != 0
        write(to: &dataStream, version: version, versionStamp: nil, classDeclared: &classDeclared)
    }

    /// `versionStamp` is the stream's version stamp, which each rule header repeats in the Outlook 2002 and later
    /// formats unless the rule has its own; nil uses the default stamp for `version`.
    internal func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion, versionStamp: UInt32?, classDeclared: inout Bool) {
        var ruleStamp = (sourceVersion == version ? self.versionStamp : nil) ?? versionStamp ?? RulesHeader.defaultVersionStamp(for: version)
        if RuleHeader.contentVersion(streamVersion: version, versionStamp: ruleStamp) < minimumVersion {
            /// The rule kept an older stamp but now has an element that needs a newer one. Raise it to the stream's,
            /// as Outlook does when the user accepts its prompt that the rule needs a newer version (spec §4.3.1).
            ruleStamp = versionStamp ?? RulesHeader.defaultVersionStamp(for: version)
        }
        let contentVersion = RuleHeader.contentVersion(streamVersion: version, versionStamp: ruleStamp)

        if !hasElementList && self.elements.isEmpty && contentVersion >= .outlook2002 {
            /// Data Size 0, with no element list (spec §4.3.1)
            var header = RuleHeader(name: storedName, enabled: enabled, numberOfElements: 0, dataSize: 0)
            header.hasElementList = false
            header.versionStamp = ruleStamp
            header.runError = runError
            header.serverRule = isServerRule ? 1 : 0
            header.flags = flags.rawValue
            header.serverRuleId = serverRuleId
            header.write(to: &dataStream, version: version)
            return
        }

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
            element.write(to: &elementsStream, version: contentVersion)
        }

        /// Data Size counts the Number of Elements field (2 bytes) and everything after it.
        let dataSize = UInt32(2 + elementsStream.data.count)
        var header = RuleHeader(name: storedName, enabled: enabled, numberOfElements: UInt16(elements.count), dataSize: dataSize)
        header.versionStamp = ruleStamp
        header.runError = runError
        header.serverRule = isServerRule ? 1 : 0
        header.flags = flags.rawValue
        header.serverRuleId = serverRuleId
        header.write(to: &dataStream, version: version)

        dataStream.write(elementsStream.data)
    }
}
