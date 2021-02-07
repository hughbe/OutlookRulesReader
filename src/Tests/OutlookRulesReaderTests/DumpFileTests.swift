import XCTest
@testable import OutlookRulesReader

final class DumpFileTests: XCTestCase {
    func testDumpRwz() throws {
        var files: [(String, String)] = []
        
        // Empty
        files.append(("Outlook97_EmptyRule", "rwz"))
        files.append(("Outlook2000_EmptyRule_98", "rwz"))
        files.append(("Outlook2000_EmptyRule_Default", "rwz"))
        files.append(("Outlook2007_EmptyRule_98", "rwz"))
        files.append(("Outlook2007_EmptyRule_2000", "rwz"))
        files.append(("Outlook2007_EmptyRule_2002", "rwz"))
        files.append(("Outlook2007_EmptyRule_Default", "rwz"))
        
        // Multiple
        files.append(("Outlook2000_Multiple_98", "rwz"))
        files.append(("Outlook2000_Multiple_Default", "rwz"))
        
        // Custom
        files.append(("New732", "rwz"))
        files.append(("New742", "rwz"))
        
        // Exported from Outlook 2019
        files.append(("Outlook2019Multiple", "rwz"))
        files.append(("Outlook98FromOutlook2019", "rwz"))
        files.append(("Outlook98FromOutlook2019_2", "rwz"))
        files.append(("Outlook2000FromOutlook2019", "rwz"))
        files.append(("Outlook2000FromOutlook2019_2", "rwz"))
        files.append(("Outlook2002FromOutlook2019", "rwz"))
        
        // Exported from Outlook 2003
        files.append(("NoSignatureFromOutlook2003", "rwz"))
        files.append(("Outlook2003All", "rwz"))
        files.append(("Outlook2003Multiple", "rwz"))

        // Conditions
        /// Outlook 2019: from <people or public group>
        /// Outlook 2007: from <people or distribution list>
        /// Outlook 98: from <people or distribution list>
        /// Outlook 97 [Addin]: from <people or distribution list>
        files.append(("Outlook97_From", "rwz"))
        files.append(("Outlook98_From", "rwz"))
        files.append(("Outlook2007_From_98", "rwz"))
        files.append(("Outlook2007_From_2000", "rwz"))
        files.append(("Outlook2007_From_2002", "rwz"))
        files.append(("Outlook2007_From_Default", "rwz"))
        
        /// Outlook 2019: with <specific words> in the subject
        /// Outlook 2007: with <specific words> in the subject
        /// Outlook 98: with <specific words> in the subject
        /// Outlook 97 [Addin]: with <specific words> in the subject
        files.append(("Outlook97_SubjectContains", "rwz"))
        files.append(("Outlook98_SubjectContains", "rwz"))
        files.append(("Outlook2007_SubjectContains_98", "rwz"))
        files.append(("Outlook2007_SubjectContains_2000", "rwz"))
        files.append(("Outlook2007_SubjectContains_2002", "rwz"))
        files.append(("Outlook2007_SubjectContains_Default", "rwz"))
        
        /// Outlook 2019: through the <specified> account
        /// Outlook 2007: through the <specified> account
        files.append(("Outlook2007_ThroughAccount_98", "rwz"))
        files.append(("Outlook2007_ThroughAccount_2000", "rwz"))
        files.append(("Outlook2007_ThroughAccount_2002", "rwz"))
        files.append(("Outlook2007_ThroughAccount_Default", "rwz"))
        
        /// Outlook 2019: sent only to me
        /// Outlook 2007: sent only to me
        /// Outlook 98: sent only to me
        /// Outlook 97 [Addin]: sent only to me
        files.append(("Outlook97_SentOnlyToMe", "rwz"))
        files.append(("Outlook98_SentOnlyToMe", "rwz"))
        files.append(("Outlook2007_SentOnlyToMe_98", "rwz"))
        files.append(("Outlook2007_SentOnlyToMe_2000", "rwz"))
        files.append(("Outlook2007_SentOnlyToMe_2002", "rwz"))
        files.append(("Outlook2007_SentOnlyToMe_Default", "rwz"))
        
        /// Outlook 2019: where my name is in the To box
        /// Outlook 2007: where my name is in the To box
        /// Outlook 98: sent directly to me
        /// Outlook 97 [Addin]: sent directly to me
        files.append(("Outlook97_SentDirectlyToMe", "rwz"))
        files.append(("Outlook98_SentDirectlyToMe", "rwz"))
        files.append(("Outlook2007_NameInToBox_98", "rwz"))
        files.append(("Outlook2007_NameInToBox_2000", "rwz"))
        files.append(("Outlook2007_NameInToBox_2002", "rwz"))
        files.append(("Outlook2007_NameInToBox_Default", "rwz"))
        
        /// Outlook 2019: marked as <importance>
        /// Outlook 2007: marked as <importance>
        /// Outlook 98: marked as <importance>
        /// Outlook 97 [Addin]: marked as <importance>
        files.append(("Outlook97_Importance", "rwz"))
        files.append(("Outlook98_Importance", "rwz"))
        files.append(("Outlook2007_Importance_98", "rwz"))
        files.append(("Outlook2007_Importance_2000", "rwz"))
        files.append(("Outlook2007_Importance_2002", "rwz"))
        files.append(("Outlook2007_Importance_Default", "rwz"))
        
        /// Outlook 2019: marked as <sensitivity>
        /// Outlook 2007: marked as <sensitivity>
        /// Outlook 98: marked as <sensitivity>
        /// Outlook 97 [Addin]: marked as <sensitivity>
        files.append(("Outlook97_Sensitivity", "rwz"))
        files.append(("Outlook98_Sensitivity", "rwz"))
        files.append(("Outlook2007_Sensitivity_98", "rwz"))
        files.append(("Outlook2007_Sensitivity_2000", "rwz"))
        files.append(("Outlook2007_Sensitivity_2002", "rwz"))
        files.append(("Outlook2007_Sensitivity_Default", "rwz"))
        
        /// Outlook 2019: flagged for <action>
        /// Outlook 2007: flagged for <action>
        /// Outlook 98: flagged for <action>
        /// Outlook 97 [Addin]: flagged for <action>
        files.append(("Outlook97_Flagged", "rwz"))
        files.append(("Outlook98_Flagged", "rwz"))
        files.append(("Outlook2007_Flagged_98", "rwz"))
        files.append(("Outlook2007_Flagged_2000", "rwz"))
        files.append(("Outlook2007_Flagged_2002", "rwz"))
        files.append(("Outlook2007_Flagged_Default", "rwz"))
        
        /// Outlook 2019: where my name is in the Cc box
        /// Outlook 2007: where my name is in the Cc box
        /// Outlook 98: where my name is in the Cc box
        /// Outlook 97 [Addin]: where my name is in the Cc box
        files.append(("Outlook97_NameInCcBox", "rwz"))
        files.append(("Outlook98_NameInCcBox", "rwz"))
        files.append(("Outlook2007_NameInCcBox_98", "rwz"))
        files.append(("Outlook2007_NameInCcBox_2000", "rwz"))
        files.append(("Outlook2007_NameInCcBox_2002", "rwz"))
        files.append(("Outlook2007_NameInCcBox_Default", "rwz"))
        
        /// Outlook 2019: where my name is in the To or Cc box
        /// Outlook 2007: where my name is in the To or Cc box
        /// Outlook 98: where my name is in the To or Cc box
        /// Outlook 97 [Addin]: where my name is in the To or Cc box
        files.append(("Outlook97_NameInToOrCcBox", "rwz"))
        files.append(("Outlook98_NameInToOrCcBox", "rwz"))
        files.append(("Outlook2007_NameInToOrCcBox_98", "rwz"))
        files.append(("Outlook2007_NameInToOrCcBox_2000", "rwz"))
        files.append(("Outlook2007_NameInToOrCcBox_2002", "rwz"))
        files.append(("Outlook2007_NameInToOrCcBox_Default", "rwz"))
        
        /// Outlook 2019: where my name is not in the To or Cc box
        /// Outlook 2007: where my name is not in the To or Cc box
        /// Outlook 98: where my name is not in the To or Cc box
        /// Outlook 97 [Addin]: where my name is not in the To or Cc box
        files.append(("Outlook97_NameNotInToBox", "rwz"))
        files.append(("Outlook98_NameNotInToBox", "rwz"))
        files.append(("Outlook2007_NameNotInToBox_98", "rwz"))
        files.append(("Outlook2007_NameNotInToBox_2000", "rwz"))
        files.append(("Outlook2007_NameNotInToBox_2002", "rwz"))
        files.append(("Outlook2007_NameNotInToBox_Default", "rwz"))
        
        /// Outlook 2019: sent to <people or public group>
        /// Outlook 2007: sent to <people or distribution list>
        /// Outlook 98: sent to <people or distribution list>
        /// Outlook 97 [Addin]: sent to <people or distribution list>
        files.append(("Outlook97_SentTo", "rwz"))
        files.append(("Outlook98_SentTo", "rwz"))
        files.append(("Outlook2007_SentTo_98", "rwz"))
        files.append(("Outlook2007_SentTo_2000", "rwz"))
        files.append(("Outlook2007_SentTo_2002", "rwz"))
        files.append(("Outlook2007_SentTo_Default", "rwz"))
        
        /// Outlook 2019: with <specific words> in the body
        /// Outlook 2007: with <specific words> in the body
        /// Outlook 98: with <specific words> in the body
        /// Outlook 97 [Addin]: with <specific words> in the body
        files.append(("Outlook97_BodyContains", "rwz"))
        files.append(("Outlook98_BodyContains", "rwz"))
        files.append(("Outlook2007_BodyContains_98", "rwz"))
        files.append(("Outlook2007_BodyContains_2000", "rwz"))
        files.append(("Outlook2007_BodyContains_2002", "rwz"))
        files.append(("Outlook2007_BodyContains_Default", "rwz"))
        
        /// Outlook 2019: with <specific words> in the subject or body
        /// Outlook 2007: with <specific words> in the subject or body
        /// Outlook 98: with <specific words> in the subject or body
        /// Outlook 97 [Addin]: with <specific words> in the subject or body
        files.append(("Outlook97_SubjectOrBodyContains", "rwz"))
        files.append(("Outlook98_SubjectOrBodyContains", "rwz"))
        files.append(("Outlook2007_SubjectOrBodyContains_98", "rwz"))
        files.append(("Outlook2007_SubjectOrBodyContains_2000", "rwz"))
        files.append(("Outlook2007_SubjectOrBodyContains_2002", "rwz"))
        files.append(("Outlook2007_SubjectOrBodyContains_Default", "rwz"))
        
        /// Outlook 2019: with <specific words> in the message's header
        /// Outlook 2007: with <specific words> in the message's header
        /// Outlook 98: with <specific words> in the message's header
        files.append(("Outlook98_HeaderContains", "rwz"))
        files.append(("Outlook2007_HeaderContains_98", "rwz"))
        files.append(("Outlook2007_HeaderContains_2000", "rwz"))
        files.append(("Outlook2007_HeaderContains_2002", "rwz"))
        files.append(("Outlook2007_HeaderContains_Default", "rwz"))
        
        /// Outlook 2007: with <specific words> in the recipient's address
        /// Outlook 98: with <specific words> in the recipient's address
        /// Outlook 97 [Addin]: with <specific words> in the recipient's address
        files.append(("Outlook97_RecipientAddressContains", "rwz"))
        files.append(("Outlook98_RecipientAddressContains", "rwz"))
        files.append(("Outlook2007_RecipientAddressContains_98", "rwz"))
        files.append(("Outlook2007_RecipientAddressContains_2000", "rwz"))
        files.append(("Outlook2007_RecipientAddressContains_2002", "rwz"))
        files.append(("Outlook2007_RecipientAddressContains_Default", "rwz"))
        
        /// Outlook 2019: with <specific words> in the sender's address
        /// Outlook 2007: with <specific words> in the sender's address
        /// Outlook 98: with <specific words> in the sender's address
        /// Outlook 97 [Addin]: with <specific words> in the sender's address
        files.append(("Outlook97_SenderAddressContains", "rwz"))
        files.append(("Outlook98_SenderAddressContains", "rwz"))
        files.append(("Outlook2007_SenderAddressContains_98", "rwz"))
        files.append(("Outlook2007_SenderAddressContains_2000", "rwz"))
        files.append(("Outlook2007_SenderAddressContains_2002", "rwz"))
        files.append(("Outlook2007_SenderAddressContains_Default", "rwz"))
        
        /// Outlook 2019: assigned to <category> category
        /// Outlook 2007: assigned to <category> category
        /// Outlook 98: assigned to <category> category
        /// Outlook 97 [Addin]: assigned to <category> category
        files.append(("Outlook97_AssignedToCategory", "rwz"))
        files.append(("Outlook98_AssignedToCategory", "rwz"))
        files.append(("Outlook2007_AssignedToCategory_98", "rwz"))
        files.append(("Outlook2007_AssignedToCategory_2000", "rwz"))
        files.append(("Outlook2007_AssignedToCategory_2002", "rwz"))
        files.append(("Outlook2007_AssignedToCategory_Default", "rwz"))
        
        /// Outlook 2019: assigned to any category
        /// Outlook 2007: assigned to any category
        files.append(("Outlook2007_AssignedToAnyCategory_98", "rwz"))
        files.append(("Outlook2007_AssignedToAnyCategory_2000", "rwz"))
        files.append(("Outlook2007_AssignedToAnyCategory_2002", "rwz"))
        files.append(("Outlook2007_AssignedToAnyCategory_Default", "rwz"))
        
        /// Outlook 2019: which is an Out Of Office message
        /// Outlook 2007: which is an Out Of Office message
        /// Outlook 98: which is an Out Of Office message
        /// Outlook 97: which is an Out Of Office message
        files.append(("Outlook97_OutOfOffice", "rwz"))
        files.append(("Outlook98_OutOfOffice", "rwz"))
        files.append(("Outlook2007_OutOfOffice_98", "rwz"))
        files.append(("Outlook2007_OutOfOffice_2000", "rwz"))
        files.append(("Outlook2007_OutOfOffice_2002", "rwz"))
        files.append(("Outlook2007_OutOfOffice_Default", "rwz"))
        
        /// Outlook 2019: which has an attachment
        /// Outlook 2007: which has an attachment
        /// Outlook 98: which has an attachment
        /// Outlook 97 [Addin]: which has an attachment
        files.append(("Outlook97_HasAttachment", "rwz"))
        files.append(("Outlook98_HasAttachment", "rwz"))
        files.append(("Outlook2007_HasAttachment_98", "rwz"))
        files.append(("Outlook2007_HasAttachment_2000", "rwz"))
        files.append(("Outlook2007_HasAttachment_2002", "rwz"))
        files.append(("Outlook2007_HasAttachment_Default", "rwz"))
        
        /// Outlook 2019: with a size <in a specific range>
        /// Outlook 2007: with a size <in a specific range>
        /// Outlook 98: with a size <in a specific range>
        /// Outlook 97 [Addin]: with a size <in a specific range>
        files.append(("Outlook97_SizeInSpecificRange", "rwz"))
        files.append(("Outlook98_SizeInSpecificRange", "rwz"))
        files.append(("Outlook2007_SizeInSpecificRange_98", "rwz"))
        files.append(("Outlook2007_SizeInSpecificRange_2000", "rwz"))
        files.append(("Outlook2007_SizeInSpecificRange_2002", "rwz"))
        files.append(("Outlook2007_SizeInSpecificRange_Default", "rwz"))

        /// Outlook 2019: received <in a specific date span>
        /// Outlook 2007: received <in a specific date span>
        /// Outlook 98: received <in a specific date span>
        /// Outlook 97 [Addin]: received <in a specific date span>
        files.append(("Outlook97_ReceivedInSpecificDateSpan", "rwz"))
        files.append(("Outlook98_ReceivedInSpecificDateSpan", "rwz"))
        files.append(("Outlook2007_ReceivedInSpecificDateSpan_98", "rwz"))
        files.append(("Outlook2007_ReceivedInSpecificDateSpan_2000", "rwz"))
        files.append(("Outlook2007_ReceivedInSpecificDateSpan_2002", "rwz"))
        files.append(("Outlook2007_ReceivedInSpecificDateSpan_Default", "rwz"))
        
        /// Outlook 2019: uses the <form name> form
        /// Outlook 2007: uses the <form name> form
        /// Outlook 98: uses the <form name> form
        /// Outlook 97 [Addin]: uses the <form name> form
        files.append(("Outlook97_UsesForm", "rwz"))
        files.append(("Outlook98_UsesForm", "rwz"))
        files.append(("Outlook2007_UsesForm_98", "rwz"))
        files.append(("Outlook2007_UsesForm_2000", "rwz"))
        files.append(("Outlook2007_UsesForm_2002", "rwz"))
        files.append(("Outlook2007_UsesForm_Default", "rwz"))
        
        /// Outlook 2019: “with <selected properties> of documents or forms”
        /// Outlook 2007: “with <selected properties> of documents or forms”
        /// Outlook 98: “with <selected properties> of documents or forms”
        files.append(("Outlook98_WithSelectedPropertiesOfDocumentsOrForms", "rwz"))
        files.append(("Outlook2007_WithSelectedPropertiesOfDocumentsOrForms_98", "rwz"))
        files.append(("Outlook2007_WithSelectedPropertiesOfDocumentsOrForms_2000", "rwz"))
        files.append(("Outlook2007_WithSelectedPropertiesOfDocumentsOrForms_2002", "rwz"))
        files.append(("Outlook2007_WithSelectedPropertiesOfDocumentsOrForms_Default", "rwz"))
        
        /// Outlook 2019: “sender is in <specified> Address Book”
        /// Outlook 2007: “sender is in <specified> Address Book”
        files.append(("Outlook2007_SenderInAddressBook_98", "rwz"))
        files.append(("Outlook2007_SenderInAddressBook_2000", "rwz"))
        files.append(("Outlook2007_SenderInAddressBook_2002", "rwz"))
        files.append(("Outlook2007_SenderInAddressBook_Default", "rwz"))
        
        /// Outlook 2019: which is an meeting invitation or update
        /// Outlook 2007: which is an meeting invitation or update
        files.append(("Outlook2007_MeetingInvitationOrUpdate_98", "rwz"))
        files.append(("Outlook2007_MeetingInvitationOrUpdate_2000", "rwz"))
        files.append(("Outlook2007_MeetingInvitationOrUpdate_2002", "rwz"))
        files.append(("Outlook2007_MeetingInvitationOrUpdate_Default", "rwz"))
        
        /// Outlook 2019: from RSS feeds with <specified text> in the title
        /// Outlook 2007: from RSS feeds with <specified text> in the title
        files.append(("Outlook2007_FromRSSFeed_98", "rwz"))
        files.append(("Outlook2007_FromRSSFeed_2000", "rwz"))
        files.append(("Outlook2007_FromRSSFeed_2002", "rwz"))
        files.append(("Outlook2007_FromRSSFeed_Default", "rwz"))
        
        /// Outlook 2019: from any RSS feed
        /// Outlook 2007: from any RSS feed
        files.append(("Outlook2007_FromAnyRSSFeed_98", "rwz"))
        files.append(("Outlook2007_FromAnyRSSFeed_2000", "rwz"))
        files.append(("Outlook2007_FromAnyRSSFeed_2002", "rwz"))
        files.append(("Outlook2007_FromAnyRSSFeed_Default", "rwz"))
        
        /// Outlook 2019: on this machine only
        /// Outlook 2007: on this machine only
        /// Outlook 2002: on this machine only
        files.append(("Outlook2007_OnThisMachineOnly_98", "rwz"))
        files.append(("Outlook2007_OnThisMachineOnly_2000", "rwz"))
        files.append(("Outlook2007_OnThisMachineOnly_2002", "rwz"))
        files.append(("Outlook2007_OnThisMachineOnly_Default", "rwz"))
        
        /// Outlook 98: suspected to be junk-email or from <Junk Senders>
        files.append(("Outlook98_Junk", "rwz"))
        
        /// Outlook 98: containing adult content or from <Adult Content Senders>
        files.append(("Outlook98_Adult", "rwz"))

        // Actions
        /// Outlook 2019: move it to the <specified> folder
        /// Outlook 2007: move it to the <specified> folder
        /// Outlook 98: move it to the <specified> folder
        /// Outlook 97 [Addin]: move it to the <specified> folder
        files.append(("Outlook97_MoveToFolder", "rwz"))
        files.append(("Outlook98_MoveToFolder", "rwz"))
        files.append(("Outlook2007_MoveToFolder_98", "rwz"))
        files.append(("Outlook2007_MoveToFolder_2000", "rwz"))
        files.append(("Outlook2007_MoveToFolder_2002", "rwz"))
        files.append(("Outlook2007_MoveToFolder_Default", "rwz"))
        
        /// Outlook 2019: assign it to the <category> category
        /// Outlook 2007: assign it to the <category> category
        /// Outlook 98: assign it to the <category> category
        /// Outlook 97: assign it to the <category> category
        files.append(("Outlook97_AssignToCategory", "rwz"))
        files.append(("Outlook98_AssignToCategory", "rwz"))
        files.append(("Outlook2007_AssignToCategory_98", "rwz"))
        files.append(("Outlook2007_AssignToCategory_2000", "rwz"))
        files.append(("Outlook2007_AssignToCategory_2002", "rwz"))
        files.append(("Outlook2007_AssignToCategory_Default", "rwz"))
        
        /// Outlook 2019: delete it
        /// Outlook 2017: delete it
        /// Outlook 98: delete it
        /// Outlook 97 [Addin]: delete it
        files.append(("Outlook97_Delete", "rwz"))
        files.append(("Outlook98_Delete", "rwz"))
        files.append(("Outlook2007_Delete_98", "rwz"))
        files.append(("Outlook2007_Delete_2000", "rwz"))
        files.append(("Outlook2007_Delete_2002", "rwz"))
        files.append(("Outlook2007_Delete_Default", "rwz"))
        
        /// Outlook 2019: permanently delete it
        /// Outlook 2007: permanently delete it
        files.append(("Outlook2007_PermanentlyDelete_98", "rwz"))
        files.append(("Outlook2007_PermanentlyDelete_2000", "rwz"))
        files.append(("Outlook2007_PermanentlyDelete_2002", "rwz"))
        files.append(("Outlook2007_PermanentlyDelete_Default", "rwz"))
        
        /// Outlook 2019: move a copy to the <specified> folder
        /// Outlook 2007: move a copy to the <specified> folder
        /// Outlook 98: move a copy to the <specified> folder
        /// Outlook 97 [Addin]: move a copy to the <specified> folder
        files.append(("Outlook97_MoveCopyToFolder", "rwz"))
        files.append(("Outlook98_MoveCopyToFolder", "rwz"))
        files.append(("Outlook2007_MoveCopyToFolder_98", "rwz"))
        files.append(("Outlook2007_MoveCopyToFolder_2000", "rwz"))
        files.append(("Outlook2007_MoveCopyToFolder_2002", "rwz"))
        files.append(("Outlook2007_MoveCopyToFolder_Default", "rwz"))
        
        /// Outlook 2019: forward it to <people or public group>
        /// Outlook 2007: forward it to <people or distribution list>
        /// Outlook 98: forward it to <people or distribution list>
        /// Outlook 97 [Addin]: forward it to <people or distribution list>
        files.append(("Outlook97_Forward", "rwz"))
        files.append(("Outlook98_Forward", "rwz"))
        files.append(("Outlook2007_Forward_98", "rwz"))
        files.append(("Outlook2007_Forward_2000", "rwz"))
        files.append(("Outlook2007_Forward_2002", "rwz"))
        files.append(("Outlook2007_Forward_Default", "rwz"))
        
        /// Outlook 2019: forward it to <people or public group> as an attachment
        /// Outlook 2007: forward it to <people or distribution list> as an attachment
        files.append(("Outlook2007_ForwardAsAttachment_98", "rwz"))
        files.append(("Outlook2007_ForwardAsAttachment_2000", "rwz"))
        files.append(("Outlook2007_ForwardAsAttachment_2002", "rwz"))
        files.append(("Outlook2007_ForwardAsAttachment_Default", "rwz"))
        
        /// Outlook 2019: reply using <template>
        /// Outlook 2007: reply using <template>
        /// Outlook 98: reply using <template>
        /// Outlook 97 [Addin]: reply using <template>
        files.append(("Outlook97_ReplyUsingTemplate", "rwz"))
        files.append(("Outlook98_ReplyUsingTemplate", "rwz"))
        files.append(("Outlook2007_ReplyUsingTemplate_98", "rwz"))
        files.append(("Outlook2007_ReplyUsingTemplate_2000", "rwz"))
        files.append(("Outlook2007_ReplyUsingTemplate_2002", "rwz"))
        files.append(("Outlook2007_ReplyUsingTemplate_Default", "rwz"))
        
        /// Outlook 2019: flag message for <follow up at this time>
        /// Outlook 2007: flag message for <follow up at this time>
        /// Outlook 98: flag message for action <in a number of days>
        /// Outlook 97 [Addin]: flag message for action <in a number of days>
        files.append(("Outlook97_FlagForFollowUp", "rwz"))
        files.append(("Outlook98_FlagForFollowUp", "rwz"))
        files.append(("Outlook2007_FlagForFollowUp_98", "rwz"))
        files.append(("Outlook2007_FlagForFollowUp_2000", "rwz"))
        files.append(("Outlook2007_FlagForFollowUp_2002", "rwz"))
        files.append(("Outlook2007_FlagForFollowUp_Default", "rwz"))
        
        /// Outlook 2019: clear the Message flag
        /// Outlook 2007: clear the Message flag
        /// Outlook 98: clear the message flag
        /// Outlook 97 [Addin]: clear the message flag
        files.append(("Outlook98_ClearFlag", "rwz"))
        files.append(("Outlook2007_ClearFlag_98", "rwz"))
        files.append(("Outlook2007_ClearFlag_2000", "rwz"))
        files.append(("Outlook2007_ClearFlag_2002", "rwz"))
        files.append(("Outlook2007_ClearFlag_Default", "rwz"))
        
        /// Outlook 2019: clear message's categories
        /// Outlook 2007: clear message's categories
        files.append(("Outlook2007_ClearCategories_98", "rwz"))
        files.append(("Outlook2007_ClearCategories_2000", "rwz"))
        files.append(("Outlook2007_ClearCategories_2002", "rwz"))
        files.append(("Outlook2007_ClearCategories_Default", "rwz"))
        
        /// Outlook 2019: mark it as <importance>
        /// Outlook 2007: mark it as <importance>
        /// Outlook 98: mark it as <importance>
        /// Outlook 97 [Addin]: mark it as <importance>
        files.append(("Outlook97_MarkAsImportance", "rwz"))
        files.append(("Outlook98_MarkAsImportance", "rwz"))
        files.append(("Outlook2007_MarkAsImportance_98", "rwz"))
        files.append(("Outlook2007_MarkAsImportance_2000", "rwz"))
        files.append(("Outlook2007_MarkAsImportance_2002", "rwz"))
        files.append(("Outlook2007_MarkAsImportance_Default", "rwz"))
        
        /// Outlook 2019: print it
        /// Outlook 2007: print it
        /// Outlook 2000: print it
        files.append(("Outlook2000_Print_98", "rwz"))
        files.append(("Outlook2000_Print_Default", "rwz"))
        files.append(("Outlook2007_Print_98", "rwz"))
        files.append(("Outlook2007_Print_2000", "rwz"))
        files.append(("Outlook2007_Print_2002", "rwz"))
        files.append(("Outlook2007_Print_Default", "rwz"))
        
        /// Outlook 2019: play <a sound>
        /// Outlook 2007: play <a sound>
        /// Outlook 98: play <a sound>
        /// Outlook 97 [Addin]: play <a sound>
        files.append(("Outlook97_PlaySound", "rwz"))
        files.append(("Outlook98_PlaySound", "rwz"))
        files.append(("Outlook2007_PlaySound_98", "rwz"))
        files.append(("Outlook2007_PlaySound_2000", "rwz"))
        files.append(("Outlook2007_PlaySound_2002", "rwz"))
        files.append(("Outlook2007_PlaySound_Default", "rwz"))
        
        /// Outlook 2007: start <application>
        files.append(("Outlook2007_StartApplication_98", "rwz"))
        files.append(("Outlook2007_StartApplication_2000", "rwz"))
        files.append(("Outlook2007_StartApplication_2002", "rwz"))
        files.append(("Outlook2007_StartApplication_Default", "rwz"))
        
        /// Outlook 2019: mark as read
        /// Outlook 2007: mark as read
        files.append(("Outlook2007_MarkAsRead_98", "rwz"))
        files.append(("Outlook2007_MarkAsRead_2000", "rwz"))
        files.append(("Outlook2007_MarkAsRead_2002", "rwz"))
        files.append(("Outlook2007_MarkAsRead_Default", "rwz"))
        
        /// Outlook 2007: run <script>
        files.append(("Outlook2007_RunScript_98", "rwz"))
        files.append(("Outlook2007_RunScript_2000", "rwz"))
        files.append(("Outlook2007_RunScript_2002", "rwz"))
        files.append(("Outlook2007_RunScript_Default", "rwz"))
        
        /// Outlook 2019: stop processing more rules
        /// Outlook 2007: stop processing more rules
        /// Outlook 98: stop processing more rules
        //TODO: files.append(("Outlook98_StopProcessingMoreRules", "rwz"))
        files.append(("Outlook2007_StopProcessingMoreRules_98", "rwz"))
        files.append(("Outlook2007_StopProcessingMoreRules_2000", "rwz"))
        files.append(("Outlook2007_StopProcessingMoreRules_2002", "rwz"))
        files.append(("Outlook2007_StopProcessingMoreRules_Default", "rwz"))
        
        /// Outlook 2007: perform <a custom action>
        /// Outlook 98: perform <a custom action>
        /// Outlook 97 [Addin]: perform <a custom action>
        files.append(("Outlook97_PerformCustomAction", "rwz"))
        //TODO: files.append(("Outlook98_PerformCustomAction", "rwz"))
        files.append(("Outlook2007_PerformCustomAction_98", "rwz"))
        files.append(("Outlook2007_PerformCustomAction_2000", "rwz"))
        files.append(("Outlook2007_PerformCustomAction_2002", "rwz"))
        files.append(("Outlook2007_PerformCustomAction_Default", "rwz"))
        
        /// Outlook 97: notify me using <a specific messsage>
        /// Outlook 98: notify me using <a specific messsage>
        files.append(("Outlook97_NotifyMe", "rwz"))
        files.append(("Outlook98_NotifyMe", "rwz"))
        files.append(("Outlook2007_DisplaySpecificMessageInNewItemAlertWindow_98", "rwz"))
        files.append(("Outlook2007_DisplaySpecificMessageInNewItemAlertWindow_2000", "rwz"))
        files.append(("Outlook2007_DisplaySpecificMessageInNewItemAlertWindow_2002", "rwz"))
        files.append(("Outlook2007_DisplaySpecificMessageInNewItemAlertWindow_Default", "rwz"))
        
        /// Outlook 2019: display a Desktop alert
        /// Outlook 2007: display a Desktop alert 
        files.append(("Outlook2007_DisplayDesktopAlert_98", "rwz"))
        files.append(("Outlook2007_DisplayDesktopAlert_2000", "rwz"))
        files.append(("Outlook2007_DisplayDesktopAlert_2002", "rwz"))
        files.append(("Outlook2007_DisplayDesktopAlert_Default", "rwz"))
        
        /// Outlook 97 [Addin]: flag message for <action in a number of days>
        files.append(("Outlook97_FlagForAction", "rwz"))
        // TODO: files.append(("Outlook98_FlagForAction", "rwz"))

        /// Outlook 97 [Addin]: notify me when it is read
        files.append(("Outlook97_NotifyRead", "rwz"))
        // TODO: files.append(("Outlook98_NotifyRead", "rwz"))
        
        /// Outlook 97 [Addin]: notify me when it is delivered
        files.append(("Outlook97_NotifyDelivered", "rwz"))
        // TODO: files.append(("Outlook97_NotifyDelivered", "rwz"))

        /// Outlook 97 [Addin]: Cc the message to <people or distribution list>
        files.append(("Outlook97_Cc", "rwz"))
        // TODO: files.append(("Outlook97_Cc", "rwz"))
        
        /// Outlook 97 [Addin]: defer delivery by <a number of> minutes
        files.append(("Outlook97_DeferDelivery", "rwz"))
        // TODO: files.append(("Outlook97_DeferDelivery", "rwz"))

        files.append(("PerformCustomAction1", "rwz"))
        files.append(("PerformCustomAction2", "rwz"))
        files.append(("PerformCustomAction3", "rwz"))
        files.append(("RedirectToPeopleOrPublicGroup", "rwz"))

        // Exceptions
        files.append(("FormsException", "rwz"))
        for (name, fileExtension) in files {
            let data = try getData(name: name, fileExtension: fileExtension)
            let rules = try OutlookRulesFile(data: data)
            print(rules)
        }
    }

    static var allTests = [
        ("testDumpRwz", testDumpRwz),
    ]
}
