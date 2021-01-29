//
//  RuleElementIdentifier.swift
//  
//
//  Created by Hugh Bellamy on 14/08/2020.
//

public enum RuleElementIdentifier: UInt32 {
    /// "type of messages to which this rule applies"
    case applyCondition = 0x00000190
    
    /// Unknown
    case unknown0x64 = 0x00000064
    
    /// “where my name is in the To box”
    case nameInToBoxCondition = 0x0000000C8
    
    /// “sent only to me”
    case sentOnlyToMeCondition = 0x0000000C9
    
    /// “where my name is not in the To box”
    case nameNotInToBoxCondition = 0x000000CA
    
    /// “from <people or public group>”
    case fromCondition = 0x000000CB
    
    /// “sent to <people or public group>”
    case sentToCondition = 0x000000CC
    
    /// “with <specific words> in the subject”
    case specificWordsInSubjectCondition = 0x000000CD
    
    /// “with <specific words> in the body”
    case specificWordsInBodyCondition = 0x000000CE
    
    /// “with <specific words> in the subject or body”
    case specificWordsInSubjectOrBodyCondition = 0x000000CF
    
    /// “flagged for <action>”
    case flaggedForActionCondition = 0x000000D0
    
    /// “marked as <importance>”
    case importanceCondition = 0x000000D2
    
    /// “marked as <sensitivity>”
    case sensitivityCondition = 0x000000D3
    
    /// “assigned to <category> category”
    case assignedToCategoryCondition = 0x000000D7
    
    /// “which is an automatic reply”
    case automaticReplyCondition = 0x000000DC
    
    /// “which has attachment”
    case hasAttachmentCondition = 0x000000DE
    
    /// “with <selected properties> of documents or forms”
    case withSelectedPropertiesOfDocumentOrFormsCondition = 0x000000DF
    
    /// “with a size <in a specific range>"
    case sizeInSpecificRangeCondition = 0x000000E0
    
    /// “received <in a specific date span>”
    case receivedInSpecificDateSpanCondition = 0x000000E1
    
    /// “where my name is in the Cc box”
    case nameInCcBoxCondition = 0x000000E2
    
    /// “where my name is in the To or Cc box”
    case nameInToOrCcBoxCondition = 0x000000E3
    
    /// “uses the <form name> form”
    case usesFormCondition = 0x000000E4
    
    /// “with <specific words> in the recipient’s address”
    case specificWordsInRecipientsAddressCondition = 0x000000E5
    
    /// “with <specific words> in the sender’s address”
    case specificWordsInSendersAddressCondition = 0x000000E6
    
    /// “with <specific words> in the message header”
    case specificWordsInMessageHeaderCondition = 0x000000E8
    
    /// “through the <specified> account”
    case throughSpecifiedAccountCondition = 0x000000EE
    
    /// “on this computer only”
    /// Outlook 2003: "on this machine only"
    case onThisComputerOnlyCondition = 0x000000EF
    
    /// “sender is in <specified> Address Book”
    case senderInSpecifiedAddressBookCondition = 0x000000F0
    
    /// “which is a meeting invitation or update”
    case whichIsAMeetingInvitationOrInviteCondition = 0x000000F1
    
    /// “from RSS feeds with <specified text> in the title”
    case fromRSSFeedsWithSpecifiedTextInTitleCondition = 0x000000F5
    
    /// “assigned to any category”
    case assignedToAnyCategoryCondition = 0x000000F6
    
    /// “from any RSS feed”
    case fromAnyRSSFeedCondition = 0x000000F7

    /// “move it to the <specified> folder”
    case moveToFolderAction = 0x0000012C
    
    /// “delete it”
    case deleteAction = 0x0000012D
    
    /// “forward it to <people or public group>”
    case forwardAction = 0x0000012E
    
    /// “reply using <template>”
    case replyUsingTemplateAction = 0x0000012F
    
    /// “display <a specific message> in the New Item Alert window”
    case displayMessageInNewItemAlertWindowAction = 0x00000130
    
    /// "flag message for <action in a number of days>"
    case flagAction = 0x00000131
    
    /// “clear the Message flag”
    case clearFlagAction = 0x00000132
    
    /// “assign it to the <category> category”
    case assignToCategoryAction = 0x00000133
    
    /// “play <sound>”
    case playSoundAction = 0x00000136
    
    /// “mark it as <importance>”
    case markImportanceAction = 0x00000137
    
    /// “mark it as <sensitivity>”
    case markSensitivityAction = 0x00000138
    
    /// “move a copy to the <specified> folder”
    case moveCopyToFolderAction = 0x00000139
    
    /// “notify me when it is read”
    case notifyReadAction = 0x0000013A
    
    /// “notify me when it is delivered”
    case notifyDeliveredAction = 0x0000013B
    
    /// “Cc the message to <people or public group>”
    case ccAction = 0x0000013C
    
    /// “defer delivery by <a number of> minutes”
    case deferDeliveryAction = 0x0000013E
    
    /// “stop processing more rules”
    case stopProcessingMoreRulesAction = 0x00000142
    
    /// "redirect it to <people or public group>"
    case redirectAction = 0x00000144
    
    /// “have server reply using <a specific message>”
    case automaticReply = 0x00000146
    
    /// “forward it to <people or public group> as attachment”
    case forwardAsAttachmentAction = 0x00000147
    
    /// “print it”
    case printAction = 0x00000148

    /// “start <application>”
    /// Note: this has been hidden in Outlook 2016
    case startApplicationAction = 0x00000149

    /// “permanently delete it”
    case permanentlyDeleteAction = 0x0000014A

    /// “run <script>”
    /// Note: this has been hidden in Outlook 2016
    case runScriptAction = 0x0000014B

    /// “mark as read”
    case markAsReadAction = 0x0000014C

    /// “display a Desktop alert”
    case displayDesktopAlertAction = 0x0000014F

    /// “flag message for <follow up at this time>”
    case flagForFollowUpAction = 0x00000151

    /// “clear message’s categories”
    case clearCategoriesAction = 0x00000152
    
    /// “except where my name is in the To box”
    case nameInToBoxException = 0x000001F4
    
    /// “except if sent only to me”
    case sentOnlyToMeException = 0x000001F5
    
    /// “except where my name is not in the To Box”
    case nameNotInToBoxException = 0x000001F6
    
    /// “except if from <people or public group>”
    case fromException = 0x000001F7
    
    /// “except if sent to <people or public group>”
    case toException = 0x000001F8
    
    /// “except if the subject contains <specific words>”
    case specificWordsInSubjectException = 0x000001F9
    
    /// “except if the body contains <specific words>”
    case specificWordsInBodyException = 0x000001FA
    
    /// “except if the subject or body contains <specific words>”
    case specificWordsInSubjectOrBodyException = 0x000001FB
    
    /// “except if it is flagged for <action>”
    case flaggedForActionException = 0x000001FC
    
    /// “except if it is marked as <importance>”
    case importanceException = 0x000001FE
    
    /// “except if it is marked as <sensitivity>”
    case sensitivityConditionException = 0x000001FF
    
    /// “except if it is assigned to <category> category”
    case assignedToCategoryException = 0x00000203
    
    /// “except if it is an automatic reply”
    case automaticReplyException = 0x00000208
    
    /// “except if it has an attachment”
    case hasAttachmentException = 0x0000020A
    
    /// “except with <selected properties> of documents or forms”
    case withSelectedPropertiesOfDocumentOrFormsException = 0x0000020B
    
    /// “except with a size <in a specific range>
    case sizeInSpecificRangeException = 0x0000020C
    
    /// “except if received <in a specific date span>
    case receivedInSpecificDateSpanException = 0x0000020D
    
    /// “except where my name is in the Cc box”
    case nameInCcBoxException = 0x0000020E
    
    /// “except if my name is in the To or Cc box”
    case nameInToOrCcBoxException = 0x0000020F
    
    /// “except if it uses the <form name> form”
    case usesFormException = 0x00000210
    
    /// “except with <specific words> in the recipient's address”
    case specificWordsInRecipientsAddressException = 0x00000211
    
    /// “except with <specific words> in the sender’s address”
    case specificWordsInSendersAddressException = 0x00000212
    
    /// “except if the message header contains <specific words>”
    case specificWordsInMessageHeaderException = 0x00000213
    
    /// “except through the <specified> account”
    case throughSpecifiedAccountException = 0x00000214
    
    /// “except if sender is <specified> Address Book”
    case senderInSpecifiedAddressBookException = 0x00000215
    
    /// “except if it is a meeting invitation or update”
    case whichIsAMeetingInvitationOrInviteException = 0x00000216
    
    /// “except if it is from RSS Feeds with <specified text> in the title”
    case fromRSSFeedsWithSpecifiedTextInTitleException = 0x00000219
    
    /// “except if it is assigned to any category”
    case assignedToAnyCategoryException = 0x0000021A
    
    /// “except from any RSS Feed”
    case fromAnyRSSFeedException = 0x0000021B
}
