//
//  OutlookRulesReadError.swift
//  
//
//  Created by Hugh Bellamy on 28/07/2020.
//

/// An error reading a rules stream. Running out of data throws `DataStreamError.noSpace` instead.
public enum OutlookRulesReadError: Error, Equatable {
    /// The class descriptor before the first rule element names a class other than `CRuleElement` (spec §2.5).
    case unknownRuleClass(ruleClass: String)
    /// A rule element is preceded by an object tag other than `0xFFFF` or `0x8001` (spec §2.5).
    case invalidObjectTag(tag: UInt16)
    /// The `CRuleElement` class descriptor appears more than once, or an element refers to it before it appears
    /// (spec §2.5).
    case invalidClassDeclaration
    /// A rule element has an identifier that no version of Outlook defines (spec §7).
    case unknownElement(identifier: UInt32)
    /// A rule element that takes no parameters declares one (spec §7).
    case unexpectedParameter(element: RuleElementIdentifier)
    /// A rule has no "apply this rule" (0x0190) element.
    case missingEventFlags
    /// A rule's DataSize doesn't match the size of its elements, so the rule was misread (spec §5.1).
    case dataSizeMismatch(dataSize: UInt32, actualSize: Int)
    /// A length, count or offset in the stream points past the data it describes.
    case lengthOutOfRange
    /// A UTF-16 string contains an unpaired surrogate.
    case invalidString
    /// An address holds a MAPI property of a type this library can't read (spec §8.4).
    case unsupportedPropertyType(type: UInt16)
}
