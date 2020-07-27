//
//  PropertyId.swift
//
//
//  Created by Hugh Bellamy on 21/07/2020.
//
//

public enum PropertyId: UInt16 {
    case tagTemplateData = 0x001
    case tagAlternateRecipientAllowed = 0x0002
    /// PidTagAcknowledgementMode
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagacknowledgementmode-canonical-property
    case tagAcknowledgementMode = 0x003
    case tagImportance = 0x0017
    case tagMessageClass = 0x001A
    case tagOriginatorDeliveryReportRequested = 0x0023
    case tagPriority = 0x0026
    case tagReadReceiptRequested = 0x0029
    case tagRecipientReassignmentProhibited = 0x002B
    case tagOriginalSensitivity = 0x002E
    /// PidTagLanguages
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtaglanguages-canonical-property
    case tagReplyTime = 0x0030
    case tagReportTag = 0x0031
    case tagReportTime = 0x0032
    /// PidTagReturnedMessageid
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagreturnedmessageid-canonical-property
    case tagReturnedMessageId = 0x0033
    /// PidTagIncompleteCopy
    /// Not documented in specification but known on internet
    /// Message API (MAPI) definitions.pdf
    case tagSecurity = 0x0034

    /// PidTagIncompleteCopy
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagincompletecopy-canonical-property
    case tagIncompleteCopy = 0x0035
    case tagSensitivity = 0x0036
    case tagSubject = 0x0037
    case tagClientSubmitTime = 0x0039
    case tagSentRepresentingSearchKey = 0x003B
    case tagSubjectPrefix = 0x003D
    case tagReceivedByEntryId = 0x003F
    case tagReceivedByName = 0x0040
    case tagSentRepresentingEntryId = 0x0041
    case tagSentRepresentingName = 0x0042
    case tagReceivedRepresentingEntryId = 0x0043
    case tagReceivedRepresentingName = 0x0044
    case tagReportEntryId = 0x0045
    case tagReadReceiptEntryId = 0x0046
    case tagMessageSubmissionId = 0x0047
    case tagProviderSubmitTime = 0x0048
    case tagOriginalSubject = 0x0049
    case tagOriginalAuthorName = 0x004D
    case tagReplyRecipientEntries = 0x004F
    case tagReplyRecipientNames = 0x0050
    case tagReceivedBySearchKey = 0x0051
    case tagReceivedRepresentingSearchKey = 0x0052
    case tagMessageToMe = 0x0057
    case tagMessageCcMe = 0x0058
    case tagMessageRecipientMe = 0x0059
    case tagOriginalSentRepresentingSearchKey = 0x005F
    case tagStartDate = 0x0060
    case tagEndDate = 0x0061
    case tagOwnerAppointmentId = 0x0062
    case tagResponseRequested = 0x0063
    case tagSentRepresentingAddressType = 0x0064
    case tagSentRepresentingEmailAddress = 0x0065
    case tagOriginalSenderAddressType = 0x0066
    case tagOriginalSenderEmailAddress = 0x0067
    case tagOriginalSentRepresentingAddressType = 0x0068
    case tagOriginalSentRepresentingEmailAddress = 0x0069
    case tagConversationTopic = 0x0070
    case tagConversationIndex = 0x0071
    case tagReceivedByAddressType = 0x0075
    case tagReceivedByEmailAddress = 0x0076
    case tagReceivedRepresentingAddressType = 0x0077
    case tagReceivedRepresentingEmailAddress = 0x0078
    case tagTransportMessageHeaders = 0x007D
    case tagTnefCorrelationKey = 0x007F

    /// PidTagReportOriginalSender
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagreportoriginalsender-canonical-property
    case tagReportOriginalSender = 0x0082
    /// PidTagReportDispositionToNames
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagreportdispositiontonames-canonical-property
    case tagReportDispositionToNames = 0x0083
    /// PidTagReportDispositionToEmailAddresses
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/he-il/office/client-developer/outlook/mapi/pidtagreportdispositiontoemailaddresses-canonical-property
    case tagReportDispositionToEmailAddresses = 0x0084
    case tagUnknown0x0086 = 0x0086
    case tagNonReceiptNotificationRequested = 0x0C06
    case tagRecipientType = 0x0C15
    case tagReplyRequested = 0x0C17
    case tagSenderEntryId = 0x0C19
    case tagSenderName = 0x0C1A
    case tagSupplementaryInfo = 0x0C1B
    case tagSenderSearchKey = 0x0C1D
    case tagSenderAddressType = 0x0C1E
    case tagSenderEmailAddress = 0x0C1F
    case unknown0 = 0x0C24
    case unknown01 = 0x0C25
    case tagDeleteAfterSubmit = 0x0E01
    case tagDisplayBcc = 0x0E02
    case tagDisplayCc = 0x0E03
    case tagDisplayTo = 0x0E04
    case tagParentDisplay = 0x0E05 // Not documented in specification - known on internet
    case tagMessageDeliveryTime = 0x0E06
    case tagMessageFlags = 0x0E07
    case tagMessageSize = 0x0E08
    case tagParentEntryId = 0x0E09
    case tagSentMailEntryId = 0x0E0A // Not documented in specification - removed
    case tagResponsibility = 0x0E0F
    /// PidTagSubmitFlags
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagsubmitflags-canonical-property
    case tagSubmitFlags = 0x0E14
    /// PidTagRecipientStatus
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagrecipientstatus-canonical-property
    case tagRecipientStatus = 0x0E15
    /// PidTagTransportKey
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-ca/office/client-developer/outlook/mapi/pidtagtransportkey-canonical-property
    case tagTransportKey = 0x0E16
    case tagMessageStatus = 0x0E17
    /// PidTagMessageDownloadTime
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagmessagedownloadtime-canonical-property
    case tagMessageDownloadTime = 0x0E18
    case tagCreationVersion = 0x0E19 // Not documented in specification - known on internet
    case tagModifyVersion = 0x0E1A // Not documented in specification - known on internet
    case tagHasAttachments = 0x0E1B
    /// PidTagBodyCrc
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagbodycrc-canonical-property
    case tagBodyCrc = 0x0E1C
    case tagNormalizedSubject = 0x0E1D
    case tagRtfInSync = 0x0E1F
    case tagAttachSize = 0x0E20
    case tagAttachNumber = 0x0E21
    case tagInternetArticleNumber = 0x0E23 // Not documented in specification - known on internet
    case tagPrimarySendAccount = 0x0E28
    case tagNextSendAcct = 0x0E29
    case tagToDoItemFlags = 0x0E2B
    case unknownBlock1 = 0x0E2F // Not documented in specification - unknown
    case unknownBlock2 = 0x0E4B // Not documented in specification - unknown
    case unknownBlock3 = 0x0E4C // Not documented in specification - unknown
    case unknownBlock4 = 0x0E4D // Not documented in specification - unknown
    case unknownBlock5 = 0x0E4E // Not documented in specification - unknown
    case creatorSid = 0x0E58 // Not documented in specification - known on internet
    case lastModifierSid = 0x0E59 // Not documented in specification - known on internet
    case tagUrlCompNamePostifix = 0x0E61 // Not documented in specification - known on internet
    case tagUrlCompNameSet = 0x0E62 // Not documented in specification - removed
    case tagSubfolderCt = 0x0E63 // Not documented in specification - known on internet
    case tagDeletedSubfolderCt = 0x0E64 // Not documented in specification - known on internet
    case unknown0x0E65 = 0x0E65
    case tagDeleteTime = 0x0E66 // Not documented in specification - known on internet
    case tagAgeLimit = 0x0E67 // Not documented in specification - known on internet
    case unknown0x0E68 = 0x0E68
    case tagRead = 0x0E69
    case tagTrustSender = 0x0E79
    case unknown0x0E9D = 0x0E9D // Not documented in specification - unknown
    case unknown0x0ECD = 0x0ECD // Not documented in specification - unknown
    case unknown0x0F02 = 0x0F02 // Not documented in specification - unknown
    case unknown0x0F03 = 0x0F03 // Not documented in specification - unknown
    case unknown0x0F0A = 0x0F0A // Not documented in specification - unknown
    case tagAccess = 0x0FF4
    case tagRowType = 0x0FF5
    case tagInstanceKey = 0x0FF6
    case tagAccessLevel = 0x0FF7
    case tagRecordKey = 0x0FF9
    case tagObjectType = 0x0FFE
    case tagEntryId = 0x0FFF
    case tagBody = 0x1000
    /// PidTagReportText
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagreporttext-canonical-property
    case tagReportText = 0x1001
    /// PidTagOriginatorAndDistributionListExpansionHistory
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagoriginatoranddistributionlistexpansionhistory-canonical-property
    case tagOriginatorAndDistributionListExpansionHistory = 0x1002
    /// PidTagReportingDistributionListName
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagreportingdistributionlistname-canonical-property
    case tagReportingDistributionListName = 0x1003
    /// PidTagReportingMessageTransferAgentCertificate
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagreportingmessagetransferagentcertificate-canonical-property
    case tagReportingMessageTransferAgentCertificate = 0x1004
    /// PidTagRtfSyncBodyCrc
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagrtfsyncbodycrc-canonical-property
    case tagRtfSyncBodyCrc = 0x1006
    /// PidTagRtfSyncBodyCount
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagrtfsyncbodycount-canonical-property
    case tagRtfSyncBodyCount = 0x1007
    /// PidTagRtfSyncBodyTag
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagrtfsyncbodytag-canonical-property
    case tagRtfSyncBodyTag = 0x1008
    case tagRtfCompressed = 0x1009
    /// PidTagRtfSyncPrefixCount
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagrtfsyncprefixcount-canonical-property
    case tagRtfSyncPrefixCount = 0x1010
    /// PidTagRtfSyncTrailingCount
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagrtfsynctrailingcount-canonical-property
    case tagRtfSyncTrailingCount = 0x1011
    /// PidTagOriginallyIntendedRecipEntryId
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagoriginallyintendedrecipentryid-canonical-property
    case tagOriginallyIntendedRecipEntryId = 0x1012
    /// PidTagHtml and PidTagBodyHtml
    /// case tagHtml = 0x1013
    case tagBodyHtml = 0x1013
    case tagBodyContentLocation = 0x1014
    case tagBodyContentId = 0x1015
    case tagNativeBody = 0x1016
    case tagInternetMessageId = 0x1035
    case tagInternetReferences = 0x1039
    case tagInReplyToId = 0x1042
    case tagListHelp = 0x1043
    case tagListSubscribe = 0x1044
    case tagListUnsubscribe = 0x1045
    case tagOriginalMessageId = 0x1046
    case tagIconIndex = 0x1080
    case tagLastVerbExecuted = 0x1081
    case tagLastVerbExecutionTime = 0x1082
    case tagFlagStatus = 0x1090
    /// PidTagFlagCompleteTime
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagflagcompletetime-canonical-property
    case tagFlagCompleteTime = 0x1091
    case unknown0x1092 = 0x1092
    /// PidTagFollowupIcon
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagfollowupicon-canonical-property
    case tagFollowupIcon = 0x1095
    case tagBlockStatus = 0x1096
    /// PidTagItemTemporaryflags
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagitemtemporaryflags-canonical-property
    case tagItemTemporaryflags = 0x1097
    /// PidTagConflictItems
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagconflictitems-canonical-property
    case tagConflictItems = 0x1098
    case tagOwaUrl = 0x10F1 // Not documented in specification - known on internet
    case tagDisableFullFidelity = 0x10F2 // Not documented in specification - known on internet
    /// PidTagUrlComponentName
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagurlcomponentname-canonical-property
    case tagUrlComponentName = 0x10F3
    case tagAttributeHidden = 0x10F4
    case tagAttributeSystem = 0x10F5 // Not documented in specification - removed
    case tagAttributeReadOnly = 0x10F6
    case unknown0x1207 = 0x1207
    case unknown0x120B = 0x120B
    case unknown0x1213 = 0x1213
    case tagRowid = 0x3000
    case tagDisplayName = 0x3001
    case tagAddressType = 0x3002
    case tagEmailAddress = 0x3003
    case tagComment = 0x3004
    case tagDepth = 0x0305
    /// PidTagProviderDisplay
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-US/office/client-developer/outlook/mapi/pidtagproviderdisplay-canonical-property
    case tagProviderDisplay = 0x0306
    case tagCreationTime = 0x3007
    case tagLastModificationTime = 0x3008
    case tagSearchKey = 0x300B
    case tagTargetEntryId = 0x3010
    case unknown12 = 0x3014
    case tagConversationIndexTracking = 0x3016
    case tagStoreSupportMask = 0x340D
    case tagStoreUnicodeMask = 0x340F // Not documented in specification - known on internet
    case unknown0x3645 = 0x3645
    case unknown0x365A = 0x365A
    case unknown0x3663 = 0x3663
    case unknown0x3666 = 0x3666
    case unknown0x3668 = 0x3668
    case unknown0x3677 = 0x3677
    case tagAttachDataBinary = 0x3701
    case tagAttachEncoding = 0x3702
    case tagAttachExtension = 0x3703
    case tagAttachFilename = 0x3704
    case tagAttachMethod = 0x3705
    case tagAttachLongFilename = 0x3707
    case tagAttachPathname = 0x3709
    case tagAttachTag = 0x370A
    case tagRenderingPosition = 0x370B
    case tagAttachMimeTag = 0x370E
    
    /// PidTagAttachMimeSequence
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagattachmimesequence-canonical-property
    case tagAttachMimeSequence = 0x3710
    case tagAttachContentId = 0x3712
    case tagAttachContentLocation = 0x3713
    case tagAttachFlags = 0x3714
    case tagAttachPayloadProviderGuidString = 0x3719
    case tagAttachPayloadClass = 0x371A
    case tagTextAttachmentCharset = 0x371B
    case unknown18 = 0x371D
    case tagDisplayType = 0x3900
    case tagDisplayTypeEx = 0x3905
    case tagSmtpAddress = 0x39FE
    case tagAddressBookDisplayNamePrintable = 0x39FF
    case tagAccount = 0x3A00
    /// PidTagAlternateRecipient
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-ca/office/client-developer/outlook/mapi/pidtagalternaterecipient-canonical-property
    case tagAlternateRecipient = 0x3A01
    case tagCallbackTelephoneNumber = 0x3A02
    /// PidTagConversionProhibited
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagconversionprohibited-canonical-property
    case tagConversionProhibited = 0x3A03
    case tagDiscloseRecipients = 0x3A04 // Not documented in specification - known on internet
    case tagGeneration = 0x3A05
    case tagGivenName = 0x3A06
    case tagGovernmentIdNumber = 0x3A07
    case tagBusinessTelephoneNumber = 0x3A08
    case tagHomeTelephoneNumber = 0x3A09
    case tagInitials = 0x3A0A
    case tagKeyword = 0x3A0B
    case tagLanguage = 0x3A0C
    case tagLocation = 0x3A0D
    /// PidTagMailPermission
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagmailpermission-canonical-property
    case tagMailPermission = 0x3A0E
    case tagMessageHandlingSystemCommonName = 0x3A0F
    case tagOrganizationalIdNumber = 0x3A10
    case tagSurname = 0x3A11
    case tagOriginalEntryId = 0x3A12
    /// PidTagOriginalDisplayName
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagoriginaldisplayname-canonical-property
    case tagOriginalDisplayName = 0x3A13
    /// PidTagOriginalSearchKey
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagoriginalsearchkey-canonical-property
    case tagOriginalSearchKey = 0x3A14
    case tagPostalAddress = 0x3A15
    case tagCompanyName = 0x3A16
    case tagTitle = 0x3A17
    case tagDepartmentName = 0x3A18
    case tagOfficeLocation = 0x3A19
    case tagPrimaryTelephoneNumber = 0x3A1A
    case tagBusiness2TelephoneNumbers = 0x3A1B
    case tagMobileTelephoneNumber = 0x3A1C
    case tagRadioTelephoneNumber = 0x3A1D
    case tagCarTelephoneNumber = 0x3A1E
    case tagOtherTelephoneNumber = 0x3A1F
    case tagTransmittableDisplayName = 0x3A20
    case tagPagerTelephoneNumber = 0x3A21
    case tagUserCertificate = 0x3A22
    case tagPrimaryFaxNumber = 0x3A23
    case tagBusinessFaxNumber = 0x3A24
    case tagHomeFaxNumber = 0x3A25
    case tagCountry = 0x3A26
    case tagLocality = 0x3A27
    case tagStateOrProvince = 0x3A28
    case tagStreetAddress = 0x3A29
    case tagPostalCode = 0x3A2A
    case tagPostOfficeBox = 0x3A2B
    case tagTelexNumber = 0x3A2C
    case tagIsdnNumber = 0x3A2D
    case tagAssistantTelephoneNumber = 0x3A2E
    case tagHome2TelephoneNumber = 0x3A2F
    case tagAssistant = 0x3A30
    case tagSendRichInfo = 0x3A40
    case tagWeddingAnniversary = 0x3A41
    case tgBirthday = 0x3A42
    case tagHobbies = 0x3A43
    case tagMiddleName = 0x3A44
    case tagDisplayNamePrefix = 0x3A45
    case tagProfession = 0x3A46
    case tagReferredByName = 0x3A47
    case tagSpouseName = 0x3A48
    case tagComputerNetworkName = 0x3A49
    case tagCustomerId = 0x3A4A
    case tagTelecommunicationsDeviceForDeafTelephoneNumber = 0x3A4B
    case tagFtpSite = 0x3A4C
    case tagGender = 0x3A4D
    case tagManagerName = 0x3A4E
    case tagNickname = 0x3A4F
    case tagPersonalHomePage = 0x3A50
    case tagBusinessHomePage = 0x3A51
    /// PidTagContactVersion
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagcontactversion-canonical-property
    case tagContactVersion = 0x3A52
    case tagContactEntryIds = 0x3A53 // Not documented - known on internet
    /// PidTagContactAddressTypes
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagcontactaddresstypes-canonical-property
    case tagContactAddressTypes = 0x3A54
    case tagContactDefaultAddressIndex = 0x3A55 // Not documented - known on internet
    case tagContactEmailAddresses = 0x3A56 // Not documented - known on internet
    case tagCompanyMainTelephoneNumber = 0x3A57
    case tagChildrensNames = 0x3A58
    case tagHomeAddressCity = 0x3A59
    case tagHomeAddressCountry = 0x3A5A
    case tagHomeAddressPostalCode = 0x3A5B
    case tagHomeAddressStateOrProvince = 0x3A5C
    case tagHomeAddressStreet = 0x3A5D
    case tagHomeAddressPostOfficeBox = 0x3A5E
    case tagOtherAddressCity = 0x3A5F
    case tagOtherAddressCountry = 0x3A60
    case tagOtherAddressPostalCode = 0x3A61
    case tagOtherAddressStateOrProvince = 0x3A62
    case tagOtherAddressStreet = 0x3A63
    case tagOtherAddressPostOfficeBox = 0x3A64
    case tagSendInternetEncoding = 0x3A71
    
    /// PidTagAbProviders
    /// Not documented in specification but known on internet
    /// https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/pidtagabproviders-canonical-property
    case tagAbProviders = 0x3D01
    case tagInitialDetailsPane = 0x3F08
    case tagPreview = 0x3FD9 // Not documented in specification - known on internet
    case tagInternetCodepage = 0x3FDE
    case tagHasDeferredActionMessages = 0x3FEA
    case tagMessageLocaleId = 0x3FF1
    case tagCreatorName = 0x3FF8
    case tagCreatorEntryId = 0x3FF9
    case tagLastModifierName = 0x3FFA
    case tagLastModifierEntryId = 0x3FFB
    case tagMessageCodepage = 0x3FFD
    case tagSenderFlags = 0x4019 // Not documented in specification - removed
    case tagSentRepresentingFlags = 0x401A
    case tagReceivedByFlags = 0x401B // Not documented in specification - removed
    case tagReceivedRepresentingFlags = 0x401C // Not documented in specification - removed
    case tagCreatorAddressType = 0x4022
    case tagCreatorEmailAddress = 0x4023
    case unknown19 = 0x4024
    case unknown20 = 0x4025
    case tagSenderSimpleDisplayName = 0x4030
    case tagSentRepresentingSimpleDisplayName = 0x4031
    case unknown21 = 0x4034
    case unknown22 = 0x4035
    case tagCreatorSimpleDisplayName = 0x4038
    case tagLastModifierSimpleDisplayName = 0x4039
    case creatorFlag = 0x4059 // Not documented in specification - known on internet
    case modifierFlag = 0x405A // Not documented in specification - known on internet
    case unknown0x5037 = 0x5037 // Not documented in specification - known on internet
    case tagInternetMailOverrideFormat = 0x5902
    case tagMessageEditorFormat = 0x5909
    case tagSenderSmtpAddress = 0x5D01
    case tagSentRepresentingSmtpAddress = 0x5D02
    case tagReceivedBySmtpAddress = 0x5D07
    case tagReceivedRepresentingSmtpAddress = 0x5D08
    case tagSendingSmtpAddress = 0x5D09 // Not documented in specification - known on internet
    case unknown23 = 0x5D0A
    case unknown24 = 0x5D0B
    case tagRecipientResourceState = 0x5FDE // Not documented in specification - removed
    case tagRecipientOrder = 0x5FDF
    case tagRecipientProposed = 0x5FE1
    case tagRecipientProposedStartTime = 0x5FE3
    case tagRecipientProposedEndTime = 0x5FE4
    case unknown25 = 0x5FE5
    case unknown26 = 0x5FEB
    case unknown27 = 0x5FEF
    case unknown28 = 0x5FF2
    case unknown29 = 0x5FF5
    case tagRecipientDisplayName = 0x5FF6
    case tagRecipientEntryId = 0x5FF7
    case tagRecipientTrackStatusTime = 0x5FFB
    case tagRecipientFlags = 0x5FFD
    case tagRecipientTrackStatus = 0x5FFF
    case dotstuffState = 0x6001 // Not documented in specification - known on internet
    case unknown0x6200 = 0x6200
    case unknown0x6201 = 0x6201
    case tagMimeSkeleton = 0x64F0
    case tagChangeKey = 0x65E2
    case tagPredecessorChangeList = 0x65E3
    case tagInConflict = 0x666C
    case unknown0x680D = 0x680D
    case unknown0x680E = 0x680E
    case unknown0x6827 = 0x6827
    case unknown0x6900 = 0x6900
    case tagProcessed = 0x7D01
    case unknown0x7D0E = 0x7D0E
    case tagAttachmentLinkId = 0x7FFA
    case tagExceptionStartTime = 0x7FFB
    case tagExceptionEndTime = 0x7FFC
    case tagAttachmentFlags = 0x7FFD
    case tagAttachmentHidden = 0x7FFE
    case tagAttachmentContactPhoto = 0x7FFF
}
