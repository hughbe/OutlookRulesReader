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
                /// Mandatory Elements
                case .eventFlags: // 0x0190
                    parameter = try EventParameter(dataStream: &dataStream, version: version)
                case .unknown0x64: // 0x0064
                    parameter = try Unknown0x64Parameter(dataStream: &dataStream, version: version)
                    
                /// Conditions
                case .nameInToBoxCondition: // 0x000C8
                    continue
                case .sentOnlyToMeCondition: // 0x000C9
                    continue
                case .nameNotInToBoxCondition: // 0x00CA
                    continue
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
                case .assignedToCategoryCondition: // 0x00D7
                    parameter = try CategoryParameter(dataStream: &dataStream, version: version)
                case .automaticReplyCondition: // 0x00DC
                    continue
                case .hasAttachmentCondition: // 0x00DE
                    continue
                case .withSelectedPropertiesOfDocumentOrFormsCondition: // 0x00DF
                    parameter = try FormParameter(dataStream: &dataStream, version: version)
                case .sizeInSpecificRangeCondition: // 0x00E0
                    parameter = try SizeParameter(dataStream: &dataStream, version: version)
                case .receivedInSpecificDateSpanCondition: // 0x00E1
                    parameter = try TimeParameter(dataStream: &dataStream, version: version)
                case .nameInCcBoxCondition: // 0x00E2
                    continue
                case .nameInToOrCcBoxCondition: // 0x00E3
                    continue
                case .usesFormCondition: // 0x00E4
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .specificWordsInRecipientsAddressCondition: // 0x00E5
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInSendersAddressCondition: // 0x00E6
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .specificWordsInMessageHeaderCondition: // 0x00E8
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .exceptionListCondition: // 0x00E9
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
                    continue
                case .alertCondition: // 0x00F3
                    parameter = try AlertParameter(dataStream: &dataStream, version: version)
                case .specificInfoPathFormCondition: // 0x00F4
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .fromRSSFeedsWithSpecifiedTextInTitleCondition: // 0x00F5
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .assignedToAnyCategoryCondition: // 0x00F6
                    continue
                case .fromAnyRSSFeedCondition: // 0x00F7
                    continue
                    
                /// Actions
                case .forwardAction: // 0x012B
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .moveToFolderAction: // 0x012C
                    parameter = try FolderParameter(dataStream: &dataStream, version: version)
                case .deleteAction: // 0x012D
                    continue
                case .replyUsingTemplateAction: // 0x012F
                    parameter = try PathParameter(dataStream: &dataStream, version: version)
                case .displayMessageInNewItemAlertWindowAction: // 0x0130
                    parameter = try MessageParameter(dataStream: &dataStream, version: version)
                case .flagAction: // 0x0131
                    parameter = try FlagRuleElementData(dataStream: &dataStream, version: version)
                case .clearFlagAction: // 0x0132
                    continue
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
                    continue
                case .notifyDeliveredAction: // 0x013B
                    continue
                case .ccAction: // 0x013C
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .deferDeliveryAction: // 0x013E
                    parameter = try DeferParameter(dataStream: &dataStream, version: version)
                case .performCustomActionAction:
                    parameter = try CustomActionParameter(dataStream: &dataStream, version: version)
                case .stopProcessingMoreRulesAction: // 0x0142
                    continue
                case .doNotSearchForCommercialOrAdultContentAction: // 0x0143
                    continue
                case .redirectAction: // 0x0144
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .addToRelevanceAction: // 0x0145
                    parameter = try RelevanceParameter(dataStream: &dataStream, version: version)
                case .automaticReply: // 0x0146
                    parameter = try TemplateParameter(dataStream: &dataStream, version: version)
                case .forwardAsAttachmentAction: // 0x0147
                    parameter = try AddressParameter(dataStream: &dataStream, version: version)
                case .printAction: // 0x0148
                    continue
                case .startApplicationAction: // 0x0149
                    parameter = try PathParameter(dataStream: &dataStream, version: version)
                case .permanentlyDeleteAction: // 0x014A
                    continue
                case .runScriptAction: // 0x014B
                    parameter = try ScriptParameter(dataStream: &dataStream, version: version)
                case .markAsReadAction: // 0x014C
                    continue
                case .displayDesktopAlertAction: // 0x014F
                    continue
                case .flagForFollowUpAction: // 0x0151
                    parameter = try FlagForFollowUpParameter(dataStream: &dataStream, version: version)
                case .clearCategoriesAction: // 0x0152
                    continue
                case .applyRetentionPolicyAction: // 0x0153
                    parameter = try RetentionPolicyParameter(dataStream: &dataStream, version: version)

                /// Exceptions
                case .nameInToBoxException: // 0x01F4
                    continue
                case .sentOnlyToMeException: // 0x01F5
                    continue
                case .nameNotInToBoxException: // 0x01F6
                    continue
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
                case .assignedToCategoryException: // 0x0203
                    parameter = try CategoryParameter(dataStream: &dataStream, version: version)
                case .automaticReplyException: // 0x0208
                    continue
                case .hasAttachmentException: // 0x020A
                    continue
                case .withSelectedPropertiesOfDocumentOrFormsException: // 0x020B
                    parameter = try FormParameter(dataStream: &dataStream, version: version)
                case .sizeInSpecificRangeException: // 0x020C
                    parameter = try SizeParameter(dataStream: &dataStream, version: version)
                case .receivedInSpecificDateSpanException: // 0x020D
                    parameter = try TimeParameter(dataStream: &dataStream, version: version)
                case .nameInCcBoxException: // 0x020E
                    continue
                case .nameInToOrCcBoxException: // 0x020F
                    continue
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
                    continue
                case .specificInfoPathFormException: // 0x0218
                    parameter = try FormTypeParameter(dataStream: &dataStream, version: version)
                case .fromRSSFeedsWithSpecifiedTextInTitleException: // 0x0219
                    parameter = try StringParameter(dataStream: &dataStream, version: version)
                case .assignedToAnyCategoryException: // 0x021A
                    continue
                case .fromAnyRSSFeedException: // 0x021B
                    continue
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
