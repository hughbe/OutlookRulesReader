//
//  RuleFlags.swift
//
//
//  Created by Hugh Bellamy on 09/11/2026.
//

/// The flags in a rule's header (spec §4.3.1.1). Rules the user creates have none. Outlook 2000 sets them on the
/// rules it creates itself (junk mail, Download Options), and finds those rules again by their flag rather than by name.
/// Present from version 970812 (Outlook 98); 0 in older formats.
public struct RuleFlags: OptionSet, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Outlook 98 and 2000 clear all the flags when the user edits a rule with this bit or `0x2` set.
    /// The meaning is unknown; probably an error that editing fixes.
    public static let unknown1 = RuleFlags(rawValue: 0x01)

    /// See `unknown1`.
    public static let unknown2 = RuleFlags(rawValue: 0x02)

    /// The junk e-mail rule: "suspected to be junk e-mail or from Junk Senders" (0x00EB), then move it to a folder.
    public static let junkEmailRule = RuleFlags(rawValue: 0x08)

    /// The adult content rule: "containing adult content or from Adult Content Senders" (0x00EC), then move it to a folder.
    public static let adultContentRule = RuleFlags(rawValue: 0x10)

    /// The "Exception List" rule: "from senders on my Exception List" (0x00E9), then
    /// "do not search message for commercial or adult content" (0x0143).
    public static let exceptionListRule = RuleFlags(rawValue: 0x20)

    /// The "big item rule" of the "Download Options" dialog: don't download messages larger than a size,
    /// except from chosen senders, with high importance or with a flag.
    public static let downloadOptionsRule = RuleFlags(rawValue: 0x40)
}
