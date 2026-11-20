//
//  AddressParameter.swift
//  
//
//  Created by Hugh Bellamy on 08/08/2020.
//

import DataStream
import MAPI

/// People or public groups, stored as a serialized MAPI `ADRLIST` (spec §6.4).
public struct AddressParameter: RuleParameter, CustomDebugStringConvertible {
    public var reserved: UInt32 = 0
    internal var lists: [AdrEntry] = []
    
    /// The properties of each address, keyed by property ID.
    public var values: [[UInt16 : Any]] {
        get {
            return lists.map { $0.properties }
        }
        set {
            // Reuse the types and order of existing properties so that unmodified properties
            // are written back unchanged.
            lists = newValue.enumerated().map { index, properties in
                AdrEntry(properties: properties, reusing: index < lists.count ? lists[index] : nil)
            }
        }
    }
    
    /// The addresses, with their common properties decoded. `values` holds every property.
    public var recipients: [Recipient] {
        values.map(Recipient.init(properties:))
    }

    /// The addresses as "Name <address>", with whether they are combined with "or" or "and".
    public var debugDescription: String {
        let addresses = recipients.map { recipient -> String in
            let name = recipient.displayName ?? "?"
            guard let address = recipient.smtpAddress ?? recipient.emailAddress, address != name else {
                return "\"\(name)\""
            }
            return "\"\(name)\" <\(address)>"
        }
        return "AddressParameter(" + addresses.joined(separator: matchAny ? " or " : " and ") + (isCc ? ", cc" : "") + ")"
    }

    /// How the addresses are combined (spec §6.4): true = "from A or B" (Outlook's choice for conditions and
    /// exceptions), false = "forward to A and B" (its choice for actions).
    public var matchAny: Bool
    /// True only for the "Cc the message to" action (spec §6.4).
    public var isCc: Bool

    /// Creates an address parameter. Outlook uses `matchAny: true` for conditions and exceptions,
    /// `matchAny: false` for actions, and `isCc: true` only for the "Cc the message to" action.
    public init(values: [[UInt16: Any]], matchAny: Bool = true, isCc: Bool = false) {
        self.matchAny = matchAny
        self.isCc = isCc
        self.values = values
    }

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Reserved (4 bytes)
        self.reserved = try dataStream.read(endianess: .littleEndian)
        
        /// Number of Values (4 bytes)
        let numberOfValues: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Values (variable)
        var lists: [AdrEntry] = []
        /// The count comes from the file, so don't reserve more than it could hold: every entry is at least 12 bytes.
        lists.reserveCapacity(min(Int(numberOfValues), dataStream.remainingCount / 12))
        for _ in 0..<numberOfValues {
            lists.append(try AdrEntry(dataStream: &dataStream))
        }
        
        self.lists = lists
        
        /// Match Any (4 bytes)
        self.matchAny = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
        
        /// Is Cc (4 bytes)
        self.isCc = (try dataStream.read(endianess: .littleEndian) as UInt32) != 0
    }

    public func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Reserved (4 bytes)
        dataStream.write(reserved, endianess: .littleEndian)
        
        /// Number of Values (4 bytes)
        dataStream.write(UInt32(lists.count), endianess: .littleEndian)
        
        /// Values (variable)
        for list in lists {
            list.write(to: &dataStream)
        }
        
        /// Match Any (4 bytes)
        dataStream.write((matchAny ? 1 : 0) as UInt32, endianess: .littleEndian)
        
        /// Is Cc (4 bytes)
        dataStream.write((isCc ? 1 : 0) as UInt32, endianess: .littleEndian)
    }
}

/// One address of an `AddressParameter`: a person or public group, as a set of MAPI properties (spec §6.4).
public struct Recipient {
    /// Every property of the address, keyed by property ID.
    public let properties: [UInt16: Any]

    public init(properties: [UInt16: Any]) {
        self.properties = properties
    }

    /// `PR_DISPLAY_NAME`, such as "First Last".
    public var displayName: String? { properties[PropertyId.tagDisplayName.rawValue] as? String }
    /// `PR_ADDRTYPE`, such as "SMTP" or "EX".
    public var addressType: String? { properties[PropertyId.tagAddressType.rawValue] as? String }
    /// `PR_EMAIL_ADDRESS`, in the format of `addressType`: an SMTP address, or an Exchange distinguished name.
    public var emailAddress: String? { properties[PropertyId.tagEmailAddress.rawValue] as? String }
    /// `PR_SMTP_ADDRESS`, when Outlook stored it. Absent for some one-off and Exchange addresses.
    public var smtpAddress: String? { properties[PropertyId.tagSmtpAddress.rawValue] as? String }
    /// `PR_ENTRYID`, the address's entry ID in its address book.
    public var entryId: [UInt8]? { properties[PropertyId.tagEntryId.rawValue] as? [UInt8] }
    /// `PR_RECIPIENT_TYPE`: 1 = To, 2 = Cc, 3 = Bcc.
    public var recipientType: UInt32? { properties[PropertyId.tagRecipientType.rawValue] as? UInt32 }
}
