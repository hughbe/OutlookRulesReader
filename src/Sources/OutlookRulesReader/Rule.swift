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
    public var applyCondition: ApplyConditionFlags!
    
    public var conditions: [RuleElement] = []
    public var actions: [RuleElement] = []
    public var exceptions: [RuleElement] = []

    public init(
        applyCondition: ApplyConditionFlags,
        name: String,
        enabled: Bool = true,
        conditions: [RuleElement] = [],
        actions: [RuleElement] = [],
        exceptions: [RuleElement] = []
    ) {
        self.applyCondition = applyCondition
        self.name = name
        self.enabled = enabled
        self.conditions = conditions
        self.actions = actions
        self.exceptions = exceptions
    }
    
    public init(dataStream: inout DataStream, index: Int, version: OutlookRulesVersion) throws {
        let header = try RuleHeader(dataStream: &dataStream, index: index, version: version)
        self.name = header.name
        self.enabled = header.enabled
        
        for i in 0..<header.numberOfElements {
            /// Identifier (4 bytes)
            let rawIdentifier: UInt32 = try dataStream.read(endianess: .littleEndian)
            guard let identifier = RuleElementIdentifier(rawValue: rawIdentifier) else {
                fatalError("Unknown identifier \(rawIdentifier.hexString)")
            }
            
            /// Data (variable)
            func addCondition<T>(type: T.Type) throws where T: RuleElementData {
                let data = try T(dataStream: &dataStream, version: version)
                conditions.append(RuleElement(identifier: identifier, data: data))
            }
            
            func addAction<T>(type: T.Type) throws where T: RuleElementData {
                let data = try T(dataStream: &dataStream, version: version)
                actions.append(RuleElement(identifier: identifier, data: data))
            }
            
            func addException<T>(type: T.Type) throws where T: RuleElementData {
                let data = try T(dataStream: &dataStream, version: version)
                exceptions.append(RuleElement(identifier: identifier, data: data))
            }

            switch identifier {
            /// Mandatory Elements
            case .applyCondition: // 0x0190
                applyCondition = try ApplyConditionRuleElementData(dataStream: &dataStream, version: version).flags
            case .unknown0x64: // 0x0064
                let _ = try RuleElement0x64Data(dataStream: &dataStream, version: version)
                
            /// Conditions
            case .nameInToBoxCondition: // 0x000C8
                try addCondition(type: SimpleRuleElementData.self)
            case .sentOnlyToMeCondition: // 0x000C9
                try addCondition(type: SimpleRuleElementData.self)
            case .nameNotInToBoxCondition: // 0x00CA
                try addCondition(type: SimpleRuleElementData.self)
            case .fromCondition: // 0x00CB
                try addCondition(type: PeopleOrPublicGroupListRuleElementData.self)
            case .sentToCondition: // 0x00CC
                try addCondition(type: PeopleOrPublicGroupListRuleElementData.self)
            case .specificWordsInSubjectCondition: // 0x00CD
                try addCondition(type: StringsListRuleElementData.self)
            case .specificWordsInBodyCondition: // 0x00CE
                try addCondition(type: StringsListRuleElementData.self)
            case .specificWordsInSubjectOrBodyCondition: // 0x00CF
                try addCondition(type: StringsListRuleElementData.self)
            case .flaggedForActionCondition: // 0x00D0
                try addCondition(type: FlaggedForActionRuleElementData.self)
            case .importanceCondition: // 0x00D2
                try addCondition(type: ImportanceRuleElementData.self)
            case .sensitivityCondition: // 0x00D3
                try addCondition(type: SensitivityRuleElementData.self)
            case .assignedToCategoryCondition: // 0x00D7
                try addCondition(type: CategoriesListRuleElementData.self)
            case .automaticReplyCondition: // 0x00DC
                try addCondition(type: SimpleRuleElementData.self)
            case .hasAttachmentCondition: // 0x00DE
                try addCondition(type: SimpleRuleElementData.self)
            case .withSelectedPropertiesOfDocumentOrFormsCondition: // 0x00DF
                try addCondition(type: WithSelectedPropertiesOfDocumentOrFormsRuleElementData.self)
            case .sizeInSpecificRangeCondition: // 0x00E0
                try addCondition(type: SizeInSpecificRangeRuleElementData.self)
            case .receivedInSpecificDateSpanCondition: // 0x00E1
                try addCondition(type: RecievedInSpecificDateSpanRuleElementData.self)
            case .nameInCcBoxCondition: // 0x00E2
                try addCondition(type: SimpleRuleElementData.self)
            case .nameInToOrCcBoxCondition: // 0x00E3
                try addCondition(type: SimpleRuleElementData.self)
            case .usesFormCondition: // 0x00E4
                try addCondition(type: UsesFormRuleElementData.self)
            case .specificWordsInRecipientsAddressCondition: // 0x00E5
                try addCondition(type: StringsListRuleElementData.self)
            case .specificWordsInSendersAddressCondition: // 0x00E6
                try addCondition(type: StringsListRuleElementData.self)
            case .specificWordsInMessageHeaderCondition: // 0x00E8
                try addCondition(type: StringsListRuleElementData.self)
            case .junkCondition: // 0x00EB
                try addCondition(type: SendersListRuleElementData.self)
            case .adultCondition: // 0x00EC
                try addCondition(type: SendersListRuleElementData.self)
            case .throughSpecifiedAccountCondition: // 0x00EE
                try addCondition(type: ThroughAccountRuleElementData.self)
            case .onThisComputerOnlyCondition: // 0x00EF
                try addCondition(type: OnThisComputerOnlyRuleElementData.self)
            case .senderInSpecifiedAddressBookCondition: // 0x00F0
                try addCondition(type: SenderInSpecifiedAddressBookRuleElementData.self)
            case .whichIsAMeetingInvitationOrInviteCondition: // 0x00F1
                try addCondition(type: SimpleRuleElementData.self)
            case .fromRSSFeedsWithSpecifiedTextInTitleCondition: // 0x00F5
                try addCondition(type: StringsListRuleElementData.self)
            case .assignedToAnyCategoryCondition: // 0x00F6
                try addCondition(type: SimpleRuleElementData.self)
            case .fromAnyRSSFeedCondition: // 0x00F7
                try addCondition(type: SimpleRuleElementData.self)
                
            /// Actions
            case .forwardAction: // 0x012B
                try addAction(type: PeopleOrPublicGroupListRuleElementData.self)
            case .moveToFolderAction: // 0x012C
                try addAction(type: MoveToFolderRuleElementData.self)
            case .deleteAction: // 0x012D
                try addAction(type: SimpleRuleElementData.self)
            case .replyUsingTemplateAction: // 0x012F
                try addAction(type: PathRuleElementData.self)
            case .displayMessageInNewItemAlertWindowAction: // 0x0130
                try addAction(type: DisplayMessageInNewItemAlertWindowRuleElementData.self)
            case .flagAction: // 0x0131
                try addAction(type: FlagRuleElementData.self)
            case .clearFlagAction: // 0x0132
                try addAction(type: SimpleRuleElementData.self)
            case .assignToCategoryAction: // 0x0133
                try addAction(type: CategoriesListRuleElementData.self)
            case .playSoundAction: // 0x0136
                try addAction(type: PathRuleElementData.self)
            case .markImportanceAction: // 0x0137
                try addAction(type: ImportanceRuleElementData.self)
            case .markSensitivityAction: // 0x0138
                try addAction(type: SensitivityRuleElementData.self)
            case .moveCopyToFolderAction: // 0x0139
                try addAction(type: MoveToFolderRuleElementData.self)
            case .notifyReadAction: // 0x013A
                try addAction(type: SimpleRuleElementData.self)
            case .notifyDeliveredAction: // 0x013B
                try addAction(type: SimpleRuleElementData.self)
            case .ccAction: // 0x013C
                try addAction(type: PeopleOrPublicGroupListRuleElementData.self)
            case .deferDeliveryAction: // 0x013E
                try addAction(type: DeferDeliveryRuleElementData.self)
            case .performCustomActionAction:
                try addAction(type: PerformCustomActionRuleElementData.self)
            case .stopProcessingMoreRulesAction: // 0x0142
                try addAction(type: SimpleRuleElementData.self)
            case .redirectAction: // 0x0143
                try addAction(type: PeopleOrPublicGroupListRuleElementData.self)
            case .automaticReply: // 0x0146
                try addAction(type: AutomaticReplyRuleElementData.self)
            case .forwardAsAttachmentAction: // 0x0147
                try addAction(type: PeopleOrPublicGroupListRuleElementData.self)
            case .printAction: // 0x0148
                try addAction(type: SimpleRuleElementData.self)
            case .startApplicationAction: // 0x0149
                try addAction(type: PathRuleElementData.self)
            case .permanentlyDeleteAction: // 0x014A
                try addAction(type: SimpleRuleElementData.self)
            case .runScriptAction: // 0x014B
                try addAction(type: RunScriptRuleElementData.self)
            case .markAsReadAction: // 0x014C
                try addAction(type: SimpleRuleElementData.self)
            case .displayDesktopAlertAction: // 0x014F
                try addAction(type: SimpleRuleElementData.self)
            case .flagForFollowUpAction: // 0x0151
                try addAction(type: FlagForFollowUpRuleElementData.self)
            case .clearCategoriesAction: // 0x0152
                try addAction(type: SimpleRuleElementData.self)
            case .applyRetentionPolicyAction: // 0x0153
                try addAction(type: ApplyRetentionPolicyRuleElementData.self)

            /// Exceptions
            case .nameInToBoxException: // 0x01F4
                try addException(type: SimpleRuleElementData.self)
            case .sentOnlyToMeException: // 0x01F5
                try addException(type: SimpleRuleElementData.self)
            case .nameNotInToBoxException: // 0x01F6
                try addException(type: SimpleRuleElementData.self)
            case .fromException: // 0x01F7
                try addException(type: PeopleOrPublicGroupListRuleElementData.self)
            case .toException: // 0x01F8
                try addException(type: PeopleOrPublicGroupListRuleElementData.self)
            case .specificWordsInSubjectException: // 0x01F9
                try addException(type: StringsListRuleElementData.self)
            case .specificWordsInBodyException: // 0x01FA
                try addException(type: StringsListRuleElementData.self)
            case .specificWordsInSubjectOrBodyException: // 0x01FB
                try addException(type: StringsListRuleElementData.self)
            case .flaggedForActionException: // 0x1FC
                try addException(type: FlaggedForActionRuleElementData.self)
            case .importanceException: // 0x01FE
                try addException(type: ImportanceRuleElementData.self)
            case .sensitivityConditionException: // 0x01FF
                try addException(type: SensitivityRuleElementData.self)
            case .assignedToCategoryException: // 0x0203
                try addException(type: CategoriesListRuleElementData.self)
            case .automaticReplyException: // 0x0208
                try addException(type: SimpleRuleElementData.self)
            case .hasAttachmentException: // 0x020A
                try addException(type: SimpleRuleElementData.self)
            case .withSelectedPropertiesOfDocumentOrFormsException: // 0x020B
                try addException(type: WithSelectedPropertiesOfDocumentOrFormsRuleElementData.self)
            case .sizeInSpecificRangeException: // 0x020C
                try addException(type: SizeInSpecificRangeRuleElementData.self)
            case .receivedInSpecificDateSpanException: // 0x020D
                try addException(type: RecievedInSpecificDateSpanRuleElementData.self)
            case .nameInCcBoxException: // 0x020E
                try addException(type: SimpleRuleElementData.self)
            case .nameInToOrCcBoxException: // 0x020F
                try addException(type: SimpleRuleElementData.self)
            case .usesFormException: // 0x0210
                try addException(type: UsesFormRuleElementData.self)
            case .specificWordsInRecipientsAddressException: // 0x0211
                try addException(type: StringsListRuleElementData.self)
            case .specificWordsInSendersAddressException: // 0x0212
                try addException(type: StringsListRuleElementData.self)
            case .specificWordsInMessageHeaderException: // 0x0213
                try addException(type: StringsListRuleElementData.self)
            case .throughSpecifiedAccountException: // 0x0214
                try addException(type: ThroughAccountRuleElementData.self)
            case .senderInSpecifiedAddressBookException: // 0x0215
                try addException(type: SenderInSpecifiedAddressBookRuleElementData.self)
            case .whichIsAMeetingInvitationOrInviteException: // 0x216
                try addException(type: SimpleRuleElementData.self)
            case .fromRSSFeedsWithSpecifiedTextInTitleException: // 0x0219
                try addException(type: StringsListRuleElementData.self)
            case .assignedToAnyCategoryException: // 0x021A
                try addException(type: SimpleRuleElementData.self)
            case .fromAnyRSSFeedException: // 0x021B
                try addException(type: SimpleRuleElementData.self)
            }

            /// Separator (2 bytes)
            if i != header.numberOfElements - 1 {
                let separator = try dataStream.read(endianess: .littleEndian) as UInt16
                if separator != 0x8001 {
                    throw OutlookRulesReadError.invalidSeparator(separator: separator)
                }
            }
        }
    }

    public var debugDescription: String {
        var s = ""
        s += "Name: \(name)"
        return s
    }
    
    public func write(to dataStream: inout OutputDataStream, index: Int) {
        var elements: [RuleElement] = [
            // First element is rule condition
            RuleElement(identifier: .applyCondition, data: ApplyConditionRuleElementData(flags: self.applyCondition)),

            // Second element is unknown (0x0064).
            RuleElement(identifier: .unknown0x64, data: RuleElement0x64Data())
        ]
        elements.append(contentsOf: conditions)
        elements.append(contentsOf: actions)
        
        let numberOfElements = UInt16(elements.count)
        let separatorDataSize = UInt32(2 * (elements.count - 1))
        
        /// Number of Rule Elements (2 bytes)
        /// Separator (2 bytes)
        /// Magic (2 bytes)
        /// Class Name Length (2 bytes)
        /// Class Name (12 bytes - CRuleElement)
        let remainingLength: UInt32 = 2 + 2 + 2 + 2 + 12
        let dataSize = elements.map { $0.dataSize }.reduce(0, +) + separatorDataSize + remainingLength

        let header = RuleHeader(name: name, enabled: enabled, numberOfElements: numberOfElements, dataSize: dataSize)
        header.write(to: &dataStream, index: index)

        for (i, element) in elements.enumerated() {
            // Element (variable)
            element.write(to: &dataStream)
            
            if i != elements.count - 1 {
                /// Separator (2 bytes)
                dataStream.write(0x8001 as UInt16, endianess: .littleEndian)
            }
        }
    }
}
