//
//  RuleElement.swift
//
//
//  Created by Hugh Bellamy on 11/08/2020.
//

import DataStream

public struct RuleElement {
    public var dataSize: UInt32 {
        8 + parameters.reduce(0, { $0 + $1.dataSize })
    }
    
    public var identifier: RuleElementIdentifier
    public var parameters: [RuleParameter]
    
    public var parameter: RuleParameter? {
        parameters.first
    }

    public init(identifier: RuleElementIdentifier, parameter: RuleParameter) {
        self.init(identifier: identifier, parameters: [parameter])
    }
    
    public init(identifier: RuleElementIdentifier, parameters: [RuleParameter] = []) {
        /// Identifier (4 bytes)
        self.identifier = identifier
        
        /// Parameters (variable)
        self.parameters = parameters
    }
    
    public init(dataStream: inout DataStream, version: OutlookRulesVersion) throws {
        /// Identifier (4 bytes)
        let identifierRaw: UInt32 = try dataStream.read(endianess: .littleEndian)
        guard let identifier = RuleElementIdentifier(rawValue: identifierRaw) else {
            throw OutlookRulesReadError.corrupted
        }
        
        self.identifier = identifier
        
        /// Number of Parameters (4 bytes)
        let numberOfParameters: UInt32 = try dataStream.read(endianess: .littleEndian)
        
        /// Parameters (variable)
        var parameters: [RuleParameter] = []
        parameters.reserveCapacity(Int(numberOfParameters))
        for _ in 0..<numberOfParameters {
            let parameter: RuleParameter
            switch identifier {
                /// Elements that don't take parameters are corrupted if they declare any.
                /// Mandatory Elements
                case .eventFlags: // 0x0190
                    parameter = try EventParameter(dataStream: &dataStream, version: version)
                case .itemType: // 0x0064
                    parameter = try ItemTypeParameter(dataStream: &dataStream, version: version)
                    
                /// Conditions
                case .nameInToBoxCondition: // 0x000C8
                    throw OutlookRulesReadError.corrupted
                case .sentOnlyToMeCondition: // 0x000C9
                    throw OutlookRulesReadError.corrupted
                case .nameNotInToBoxCondition: // 0x00CA
                    throw OutlookRulesReadError.corrupted
                case .fromCondition: // 0x00CB
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .sentToCondition: // 0x00CC
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSubjectCondition: // 0x00CD
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInBodyCondition: // 0x00CE
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSubjectOrBodyCondition: // 0x00CF
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .flaggedForActionCondition: // 0x00D0
                    parameter = try FlaggedForActionParameter(dataStream: &dataStream, version: version)
                case .importanceCondition: // 0x00D2
                    parameter = try ImportanceParameter(dataStream: &dataStream, version: version)
                case .sensitivityCondition: // 0x00D3
                    parameter = try SensitivityParameter(dataStream: &dataStream, version: version)
                case .nameInToBoxMeetingCondition: // 0x00D4
                    throw OutlookRulesReadError.corrupted
                case .nameNotInToBoxMeetingCondition: // 0x00D5
                    throw OutlookRulesReadError.corrupted
                case .sentToAsCcCondition: // 0x00DA
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .sentToAlternateCondition: // 0x00DB
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .assignedToCategoryCondition: // 0x00D7
                    parameter = try CategoryParameter(dataStream: &dataStream, version: version)
                case .automaticReplyCondition: // 0x00DC
                    throw OutlookRulesReadError.corrupted
                case .hasAttachmentCondition: // 0x00DE
                    throw OutlookRulesReadError.corrupted
                case .withSelectedPropertiesOfDocumentOrFormsCondition: // 0x00DF
                    parameter = try FormParameter(dataStream: &dataStream, version: version)
                case .sizeInSpecificRangeCondition: // 0x00E0
                    parameter = try SizeParameter(dataStream: &dataStream, version: version)
                case .receivedInSpecificDateSpanCondition: // 0x00E1
                    parameter = try TimeParameter(dataStream: &dataStream, version: version)
                case .nameInCcBoxCondition: // 0x00E2
                    throw OutlookRulesReadError.corrupted
                case .nameInToOrCcBoxCondition: // 0x00E3
                    throw OutlookRulesReadError.corrupted
                case .usesFormCondition: // 0x00E4
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .specificWordsInRecipientsAddressCondition: // 0x00E5
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSendersAddressCondition: // 0x00E6
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .netFoldersCondition: // 0x00E7
                    throw OutlookRulesReadError.corrupted
                case .specificWordsInMessageHeaderCondition: // 0x00E8
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .exceptionListCondition: // 0x00E9
                    parameter = try SendersListParameter(dataStream: &dataStream, version: version)
                case .legacyJunkCondition: // 0x00EA
                    parameter = try SendersListParameter(dataStream: &dataStream, version: version)
                case .junkCondition: // 0x00EB
                    parameter = try SendersListParameter(dataStream: &dataStream, version: version)
                case .adultCondition: // 0x00EC
                    parameter = try SendersListParameter(dataStream: &dataStream, version: version)
                case .relevanceInSpecificRangeCondition: // 0x00ED
                    parameter = try RelevanceRangeParameter(dataStream: &dataStream, version: version)
                case .throughSpecifiedAccountCondition: // 0x00EE
                    parameter = try AccountParameter(dataStream: &dataStream, version: version)
                case .onThisComputerOnlyCondition: // 0x00EF
                    parameter = try ProfileStampParameter(dataStream: &dataStream, version: version)
                case .senderInSpecifiedAddressBookCondition: // 0x00F0
                    parameter = try AddressBookParameter(dataStream: &dataStream, version: version)
                case .whichIsAMeetingInvitationOrInviteCondition: // 0x00F1
                    throw OutlookRulesReadError.corrupted
                case .alertCondition: // 0x00F3
                    parameter = try AlertParameter(dataStream: &dataStream, version: version)
                case .specificInfoPathFormCondition: // 0x00F4
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .fromRSSFeedsWithSpecifiedTextInTitleCondition: // 0x00F5
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .assignedToAnyCategoryCondition: // 0x00F6
                    throw OutlookRulesReadError.corrupted
                case .fromAnyRSSFeedCondition: // 0x00F7
                    parameter = try ReservedParameter(dataStream: &dataStream, version: version)
                    
                /// Actions
                case .forwardAction: // 0x012E
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .moveToFolderAction: // 0x012C
                    parameter = try FolderParameter(dataStream: &dataStream, version: version)
                case .deleteAction: // 0x012D
                    throw OutlookRulesReadError.corrupted
                case .replyUsingTemplateAction: // 0x012F
                    parameter = try PathParameter(dataStream: &dataStream, version: version)
                case .displayMessageInNewItemAlertWindowAction: // 0x0130
                    parameter = try MessageParameter(dataStream: &dataStream, version: version)
                case .flagAction: // 0x0131
                    parameter = try FlagParameter(dataStream: &dataStream, version: version)
                case .clearFlagAction: // 0x0132
                    throw OutlookRulesReadError.corrupted
                case .assignToCategoryAction: // 0x0133
                    parameter = try CategoryParameter(dataStream: &dataStream, version: version)
                case .playSoundAction: // 0x0136
                    parameter = try PathParameter(dataStream: &dataStream, version: version)
                case .markImportanceAction: // 0x0137
                    parameter = try ImportanceParameter(dataStream: &dataStream, version: version)
                case .markSensitivityAction: // 0x0138
                    parameter = try SensitivityParameter(dataStream: &dataStream, version: version)
                case .moveCopyToFolderAction: // 0x0139
                    parameter = try FolderParameter(dataStream: &dataStream, version: version)
                case .notifyReadAction: // 0x013A
                    throw OutlookRulesReadError.corrupted
                case .notifyDeliveredAction: // 0x013B
                    throw OutlookRulesReadError.corrupted
                case .ccAction: // 0x013C
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .deferDeliveryAction: // 0x013E
                    parameter = try DeferParameter(dataStream: &dataStream, version: version)
                case .performCustomActionAction: // 0x013F
                    parameter = try CustomActionParameter(dataStream: &dataStream, version: version)
                case .netFoldersAction: // 0x0141
                    throw OutlookRulesReadError.corrupted
                case .unusedAction: // 0x0140
                    throw OutlookRulesReadError.corrupted
                case .stopProcessingMoreRulesAction: // 0x0142
                    throw OutlookRulesReadError.corrupted
                case .doNotSearchForCommercialOrAdultContentAction: // 0x0143
                    throw OutlookRulesReadError.corrupted
                case .redirectAction: // 0x0144
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .addToRelevanceAction: // 0x0145
                    parameter = try RelevanceParameter(dataStream: &dataStream, version: version)
                case .automaticReply: // 0x0146
                    parameter = try TemplateParameter(dataStream: &dataStream, version: version)
                case .forwardAsAttachmentAction: // 0x0147
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .printAction: // 0x0148
                    throw OutlookRulesReadError.corrupted
                case .startApplicationAction: // 0x0149
                    parameter = try PathParameter(dataStream: &dataStream, version: version)
                case .permanentlyDeleteAction: // 0x014A
                    throw OutlookRulesReadError.corrupted
                case .runScriptAction: // 0x014B
                    parameter = try ScriptParameter(dataStream: &dataStream, version: version)
                case .markAsReadAction: // 0x014C
                    throw OutlookRulesReadError.corrupted
                case .hiddenServerReplyAction: // 0x014D
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .dotNetNotificationAction: // 0x014E
                    throw OutlookRulesReadError.corrupted
                case .displayDesktopAlertAction: // 0x014F
                    throw OutlookRulesReadError.corrupted
                case .flagColorAction: // 0x0150
                    parameter = try FlagColorParameter(dataStream: &dataStream, version: version)
                case .flagForFollowUpAction: // 0x0151
                    parameter = try FlagForFollowUpParameter(dataStream: &dataStream, version: version)
                case .clearCategoriesAction: // 0x0152
                    throw OutlookRulesReadError.corrupted
                case .applyRetentionPolicyAction: // 0x0153
                    parameter = try RetentionPolicyParameter(dataStream: &dataStream, version: version)

                /// Exceptions
                case .nameInToBoxException: // 0x01F4
                    throw OutlookRulesReadError.corrupted
                case .sentOnlyToMeException: // 0x01F5
                    throw OutlookRulesReadError.corrupted
                case .nameNotInToBoxException: // 0x01F6
                    throw OutlookRulesReadError.corrupted
                case .fromException: // 0x01F7
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .toException: // 0x01F8
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSubjectException: // 0x01F9
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInBodyException: // 0x01FA
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSubjectOrBodyException: // 0x01FB
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .flaggedForActionException: // 0x1FC
                    parameter = try FlaggedForActionParameter(dataStream: &dataStream, version: version)
                case .importanceException: // 0x01FE
                    parameter = try ImportanceParameter(dataStream: &dataStream, version: version)
                case .sensitivityConditionException: // 0x01FF
                    parameter = try SensitivityParameter(dataStream: &dataStream, version: version)
                case .nameInToBoxMeetingException: // 0x0200
                    throw OutlookRulesReadError.corrupted
                case .nameNotInToBoxMeetingException: // 0x0201
                    throw OutlookRulesReadError.corrupted
                case .sentToAsCcException: // 0x0206
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .sentToAlternateException: // 0x0207
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .assignedToCategoryException: // 0x0203
                    parameter = try CategoryParameter(dataStream: &dataStream, version: version)
                case .automaticReplyException: // 0x0208
                    throw OutlookRulesReadError.corrupted
                case .hasAttachmentException: // 0x020A
                    throw OutlookRulesReadError.corrupted
                case .withSelectedPropertiesOfDocumentOrFormsException: // 0x020B
                    parameter = try FormParameter(dataStream: &dataStream, version: version)
                case .sizeInSpecificRangeException: // 0x020C
                    parameter = try SizeParameter(dataStream: &dataStream, version: version)
                case .receivedInSpecificDateSpanException: // 0x020D
                    parameter = try TimeParameter(dataStream: &dataStream, version: version)
                case .nameInCcBoxException: // 0x020E
                    throw OutlookRulesReadError.corrupted
                case .nameInToOrCcBoxException: // 0x020F
                    throw OutlookRulesReadError.corrupted
                case .usesFormException: // 0x0210
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .specificWordsInRecipientsAddressException: // 0x0211
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSendersAddressException: // 0x0212
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInMessageHeaderException: // 0x0213
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .throughSpecifiedAccountException: // 0x0214
                    parameter = try AccountParameter(dataStream: &dataStream, version: version)
                case .senderInSpecifiedAddressBookException: // 0x0215
                    parameter = try AddressBookParameter(dataStream: &dataStream, version: version)
                case .whichIsAMeetingInvitationOrInviteException: // 0x0216
                    throw OutlookRulesReadError.corrupted
                case .specificInfoPathFormException: // 0x0218
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .fromRSSFeedsWithSpecifiedTextInTitleException: // 0x0219
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .assignedToAnyCategoryException: // 0x021A
                    throw OutlookRulesReadError.corrupted
                case .fromAnyRSSFeedException: // 0x021B
                    parameter = try ReservedParameter(dataStream: &dataStream, version: version)
            }
            
            parameters.append(parameter)
        }
        
        self.parameters = parameters
    }
    
    func write(to dataStream: inout OutputDataStream, version: OutlookRulesVersion) {
        /// Identifier (4 bytes)
        dataStream.write(identifier.rawValue, endianess: .littleEndian)
        
        /// Number of Parameters (4 bytes)
        dataStream.write(UInt32(parameters.count), endianess: .littleEndian)
        
        /// Data (variable)
        for parameter in parameters {
            parameter.write(to: &dataStream, version: version)
        }
    }
}
