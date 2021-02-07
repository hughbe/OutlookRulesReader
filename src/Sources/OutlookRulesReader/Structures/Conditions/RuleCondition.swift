//
//  RuleCondition.swift
//  
//
//  Created by Hugh Bellamy on 30/01/2021.
//

import DataStream

public enum RuleCondition {
    case nameInToBox
    case sentOnlyToMe
    case nameNotInToBox
    case from(_: PeopleOrPublicGroupListRuleElementData)
    case sentTo(_: PeopleOrPublicGroupListRuleElementData)
    case specificWordsInSubject(_: StringsListRuleElementData)
    case specificWordsInBody(_: StringsListRuleElementData)
    case specificWordsInSubjectOrBody(_: StringsListRuleElementData)
    case flaggedForAction(_: FlaggedForActionRuleElementData)
    case importance(_: ImportanceRuleElementData)
    case sensitivity(_: SensitivityRuleElementData)
    case assignedToCategory(_: CategoriesListRuleElementData)
    case automaticReply
    case hasAttachment
    case withSelectedPropertiesOfDocumentOrForms(_: WithSelectedPropertiesOfDocumentOrFormsRuleElementData)
    case sizeInSpecificRange(_: SizeInSpecificRangeRuleElementData)
    case receivedInSpecificDateSpan(_: RecievedInSpecificDateSpanRuleElementData)
    case nameInCcBox
    case nameInToOrCcBox
    case usesForm(_: UsesFormRuleElementData)
    case specificWordsInRecipientsAddress(_: StringsListRuleElementData)
    case specificWordsInSendersAddress(_: StringsListRuleElementData)
    case specificWordsInMessageHeader(_: StringsListRuleElementData)
    case throughSpecifiedAccount(_: ThroughAccountRuleElementData)
    case junk(_: SendersListRuleElementData)
    case adult(_: SendersListRuleElementData)
    case onThisComputerOnly(_: OnThisComputerOnlyRuleElementData)
    case senderInSpecifiedAddressBook(_: SenderInSpecifiedAddressBookRuleElementData)
    case whichIsAMeetingInvitationOrInvite
    case fromRSSFeedsWithSpecifiedTextInTitle(_: StringsListRuleElementData)
    case assignedToAnyCategory
    case fromAnyRSSFeed

    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        let idRaw: UInt32 = try dataStream.read(endianess: .littleEndian)
        guard let id = RuleElementIdentifier(rawValue: idRaw) else {
            throw OutlookRulesReadError.corrupted
        }
        
        switch id {
        case .nameInToBoxCondition:
            /// “where my name is in the To box”
            let _ = try SimpleRuleElementData(dataStream: &dataStream, version: version)
            self = .nameInToBox
        case .sentOnlyToMeCondition:
            /// “sent only to me”
            let _ = try SimpleRuleElementData(dataStream: &dataStream, version: version)
            self = .sentOnlyToMe
        case .nameNotInToBoxCondition:
            /// “where my name is not in the To box”
            let _ = try SimpleRuleElementData(dataStream: &dataStream, version: version)
            self = .nameNotInToBox
        case .fromCondition:
            /// “from <people or public group>”
            self = .from(try PeopleOrPublicGroupListRuleElementData(dataStream: &dataStream, version: version))
        case .sentToCondition:
            /// “sent to <people or public group>”
            self = .sentTo(try PeopleOrPublicGroupListRuleElementData(dataStream: &dataStream, version: version))
        case .specificWordsInSubjectCondition:
            /// “with <specific words> in the subject”
            self = .specificWordsInSubject(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .specificWordsInBodyCondition:
            /// “with <specific words> in the body”
            self = .specificWordsInBody(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .specificWordsInSubjectOrBodyCondition:
            /// “with <specific words> in the subject or body”
            self = .specificWordsInSubjectOrBody(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .flaggedForActionCondition:
            /// “flagged for <action>”
            self = .flaggedForAction(try FlaggedForActionRuleElementData(dataStream: &dataStream, version: version))
        case .importanceCondition:
            /// “marked as <importance>”
            self = .importance(try ImportanceRuleElementData(dataStream: &dataStream, version: version))
        case .sensitivityCondition:
            /// “marked as <sensitivity>”
            self = .sensitivity(try SensitivityRuleElementData(dataStream: &dataStream, version: version))
        case .assignedToCategoryCondition:
            /// “assigned to <category> category”
            self = .assignedToCategory(try CategoriesListRuleElementData(dataStream: &dataStream, version: version))
        case .automaticReplyCondition:
            /// “which is an automatic reply”
            self = .automaticReply
        case .hasAttachmentCondition:
            /// “which has attachment”
            self = .hasAttachment
        case .withSelectedPropertiesOfDocumentOrFormsCondition:
            /// “with <selected properties> of documents or forms”
            self = .withSelectedPropertiesOfDocumentOrForms(try WithSelectedPropertiesOfDocumentOrFormsRuleElementData(dataStream: &dataStream, version: version))
        case .sizeInSpecificRangeCondition:
            /// “with a size <in a specific range>"
            self = .sizeInSpecificRange(try SizeInSpecificRangeRuleElementData(dataStream: &dataStream, version: version))
        case .receivedInSpecificDateSpanCondition:
            /// “received <in a specific date span>”
            self = .receivedInSpecificDateSpan(try RecievedInSpecificDateSpanRuleElementData(dataStream: &dataStream, version: version))
        case .nameInCcBoxCondition:
            /// “where my name is in the Cc box”
            self = .nameInCcBox
        case .nameInToOrCcBoxCondition:
            /// “where my name is in the To or Cc box”
            self = .nameInToOrCcBox
        case .usesFormCondition:
            /// “uses the <form name> form”
            self = .usesForm(try UsesFormRuleElementData(dataStream: &dataStream, version: version))
        case .specificWordsInRecipientsAddressCondition:
            /// “with <specific words> in the recipient’s address”
            self = .specificWordsInRecipientsAddress(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .specificWordsInSendersAddressCondition:
            /// “with <specific words> in the sender’s address”
            self = .specificWordsInSendersAddress(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .specificWordsInMessageHeaderCondition:
            /// “with <specific words> in the message header”
            self = .specificWordsInMessageHeader(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .throughSpecifiedAccountCondition:
            /// “through the <specified> account”
            self = .throughSpecifiedAccount(try ThroughAccountRuleElementData(dataStream: &dataStream, version: version))
        case .junkCondition:
            /// "suspected to be junk-email or from <Junk Senders>"
            self = .junk(try SendersListRuleElementData(dataStream: &dataStream, version: version))
        case .adultCondition:
            /// "containing adult content or from <Adult Content Senders>"
            self = .adult(try SendersListRuleElementData(dataStream: &dataStream, version: version))
        case .onThisComputerOnlyCondition:
            /// “on this computer only”
            /// Outlook 2003: "on this machine only"
            self = .onThisComputerOnly(try OnThisComputerOnlyRuleElementData(dataStream: &dataStream, version: version))
        case .senderInSpecifiedAddressBookCondition:
            /// “sender is in <specified> Address Book”
            self = .senderInSpecifiedAddressBook(try SenderInSpecifiedAddressBookRuleElementData(dataStream: &dataStream, version: version))
        case .whichIsAMeetingInvitationOrInviteCondition:
            /// “which is a meeting invitation or update”
            self = .whichIsAMeetingInvitationOrInvite
        case .fromRSSFeedsWithSpecifiedTextInTitleCondition:
            /// “from RSS feeds with <specified text> in the title”
            self = .fromRSSFeedsWithSpecifiedTextInTitle(try StringsListRuleElementData(dataStream: &dataStream, version: version))
        case .assignedToAnyCategoryCondition:
            /// “assigned to any category”
            self = .assignedToAnyCategory
        case .fromAnyRSSFeedCondition:
            /// “from any RSS feed"
            self = .fromAnyRSSFeed
        default:
            #if DEBUG
            fatalError("NYI: \(id)")
            #else
            throw OutlookRulesReadError.corrupted
            #endif
        }
    }
}
