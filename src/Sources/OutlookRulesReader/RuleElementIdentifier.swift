//
//  RuleElementIdentifier.swift
//  
//
//  Created by Hugh Bellamy on 14/08/2020.
//

public enum RuleElementIdentifier: UInt32 {
    case applyCondition = 0x0190
    case unknown0x64 = 0x0064
    
    // Conditions
    case nameInToBoxCondition = 0x000C8
    case sentOnlyToMeCondition = 0x000C9
    case nameNotInToBoxCondition = 0x00CA
    case fromCondition = 0x00CB
    case sentToCondition = 0x00CC
    case specificWordsInSubjectCondition = 0x00CD
    case specificWordsInBodyCondition = 0x00CE
    case specificWordsInSubjectOrBodyCondition = 0x00CF
    case flaggedForActionCondition = 0x00D0
    case SensitivityRuleElementDataImportanceCondition = 0x00D2
    case sensitivityCondition = 0x00D3
    case assignedToCategoryCondition = 0x00D7
    case automaticReplyCondition = 0x00DC
    case hasAttachmentCondition = 0x00DE
    case withSelectedPropertiesOfDocumentOrFormsCondition = 0x00DF
    case sizeInSpecificRangeCondition = 0x00E0
    case receivedInSpecificDateSpanCondition = 0x00E1
    case nameInCcBoxCondition = 0x00E2
    case nameInToOrCcBoxCondition = 0x00E3
    case usesFormCondition = 0x00E4
    case specificWordsInRecipientsAddressCondition = 0x00E5
    case specificWordsInSendersAddressCondition = 0x00E6
    case specificWordsInMessageHeaderCondition = 0x00E8
    case throughSpecifiedAccountCondition = 0x00EE
    case onThisComputerOnlyCondition = 0x00EF
    case senderInSpecifiedAddressBookCondition = 0x00F0
    case whichIsAMeetingInvitationOrInviteCondition = 0x00F1
    case fromRSSFeedsWithSpecifiedTextInTitleCondition = 0x00F5
    case assignedToAnyCategoryCondition = 0x00F6
    case fromAnyRSSFeedCondition = 0x00F7

    // Actions
    case moveToFolderAction = 0x012C
    case deleteAction = 0x012D
    case forwardAction = 0x012E
    case replyUsingTemplateAction = 0x012F
    case displayMessageInNewItemAlertWindowAction = 0x0130
    case flagAction = 0x0131
    case clearFlagAction = 0x0132
    case assignToCategoryAction = 0x0133
    case playSoundAction = 0x0136
    case markImportanceAction = 0x0137
    case markSensitivityAction = 0x0138
    case moveCopyToFolderAction = 0x0139
    case notifyReadAction = 0x013A
    case notifyDeliveredAction = 0x013B
    case ccAction = 0x013C
    case deferDeliveryAction = 0x013E
    case stopProcessingMoreRulesAction = 0x0142
    case forwardAsAttachmentAction = 0x0147
    case printAction = 0x0148
    /// Removed (hidden) in Outlook 2016
    case startApplicationAction = 0x0149
    case permanentlyDeleteAction = 0x014A
    /// Removed (hidden) in Outlook 2016
    case runScriptAction = 0x014B
    case markAsReadAction = 0x014C
    case displayDesktopAlertAction = 0x014F
    case flagForFollowUpAction = 0x0151
    case clearCategoriesAction = 0x0152
    
    // Exceptions
    case nameInToBoxException = 0x01F4
    case sentOnlyToMeException = 0x01F5
    case nameNotInToBoxException = 0x01F6
    case fromException = 0x01F7
    case toException = 0x01F8
    case specificWordsInSubjectException = 0x01F9
    case specificWordsInBodyException = 0x01FA
    case specificWordsInSubjectOrBodyException = 0x01FB
    case flaggedForActionException = 0x01FC
    case SensitivityRuleElementDataImportanceException = 0x01FE
    case sensitivityConditionException = 0x01FF
    case assignedToCategoryException = 0x0203
    case automaticReplyException = 0x0208
    case hasAttachmentException = 0x020A
    case withSelectedPropertiesOfDocumentOrFormsException = 0x020B
    case sizeInSpecificRangeException = 0x020C
    case receivedInSpecificDateSpanException = 0x020D
    case nameInCcBoxException = 0x020E
    case nameInToOrCcBoxException = 0x020F
    case usesFormException = 0x0210
    case specificWordsInRecipientsAddressException = 0x0211
    case specificWordsInSendersAddressException = 0x0212
    case specificWordsInMessageHeaderException = 0x0213
    case throughSpecifiedAccountException = 0x0214
    case senderInSpecifiedAddressBookException = 0x0215
    case whichIsAMeetingInvitationOrInviteException = 0x0216
    case fromRSSFeedsWithSpecifiedTextInTitleException = 0x0219
    case assignedToAnyCategoryException = 0x021A
    case fromAnyRSSFeedException = 0x021B
}
