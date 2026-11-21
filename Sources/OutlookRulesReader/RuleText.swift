//
//  RuleText.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

import Foundation

public extension RuleElementIdentifier {
    /// How Outlook's Rules Wizard words the element, with its value in asterisks, such as "from *people or public
    /// group*" (spec §7). Exceptions use the wording of their condition.
    var textTemplate: String {
        switch self {
        case .eventFlags: return "apply this rule *after the message arrives*"
        case .itemType: return "for each *message*"
        case .nameInToBoxCondition: return "where my name is in the To box"
        case .sentOnlyToMeCondition: return "sent only to me"
        case .nameNotInToBoxCondition: return "where my name is not in the To box"
        case .fromCondition: return "from *people or public group*"
        case .sentToCondition: return "sent to *people or public group*"
        case .specificWordsInSubjectCondition: return "with *specific words* in the subject"
        case .specificWordsInBodyCondition: return "with *specific words* in the body"
        case .specificWordsInSubjectOrBodyCondition: return "with *specific words* in the subject or body"
        case .flaggedForActionCondition: return "flagged for *action*"
        case .importanceCondition: return "marked as *importance*"
        case .sensitivityCondition: return "marked as *sensitivity*"
        case .nameInToBoxMeetingCondition: return "where my name is in the To box and it is a meeting"
        case .nameNotInToBoxMeetingCondition: return "where my name is not in the To box and it is a meeting"
        case .assignedToCategoryCondition: return "assigned to *category* category"
        case .sentToAsCcCondition: return "sent to *people or public group* as Cc"
        case .sentToAlternateCondition: return "sent to *people or public group*"
        case .automaticReplyCondition: return "which is an automatic reply"
        case .hasAttachmentCondition: return "which has an attachment"
        case .withSelectedPropertiesOfDocumentOrFormsCondition: return "with *selected properties* of documents or forms"
        case .sizeInSpecificRangeCondition: return "with a size *in a specific range*"
        case .receivedInSpecificDateSpanCondition: return "received *in a specific date span*"
        case .nameInCcBoxCondition: return "where my name is in the Cc box"
        case .nameInToOrCcBoxCondition: return "where my name is in the To or Cc box"
        case .usesFormCondition: return "uses the *form name* form"
        case .specificWordsInRecipientsAddressCondition: return "with *specific words* in the recipient's address"
        case .specificWordsInSendersAddressCondition: return "with *specific words* in the sender's address"
        case .netFoldersCondition: return "use Net Folders"
        case .specificWordsInMessageHeaderCondition: return "with *specific words* in the message header"
        case .exceptionListCondition: return "from senders on my *Exception List*"
        case .legacyJunkCondition: return "suspected to be junk e-mail or from *Junk Senders*"
        case .junkCondition: return "suspected to be junk e-mail or from *Junk Senders*"
        case .adultCondition: return "containing adult content or from *Adult Content Senders*"
        case .relevanceInSpecificRangeCondition: return "with a relevance *in a specific range*"
        case .throughSpecifiedAccountCondition: return "through the *specified* account"
        case .onThisComputerOnlyCondition: return "on this computer only"
        case .senderInSpecifiedAddressBookCondition: return "sender is in *specified* Address Book"
        case .whichIsAMeetingInvitationOrInviteCondition: return "which is a meeting invitation or update"
        case .alertCondition: return "which is an *Alert E-mail*"
        case .specificInfoPathFormCondition: return "of the *specific* form type (InfoPath)"
        case .fromRSSFeedsWithSpecifiedTextInTitleCondition: return "from RSS feeds with *specified text* in the title"
        case .assignedToAnyCategoryCondition: return "assigned to any category"
        case .fromAnyRSSFeedCondition: return "from any RSS feed"
        case .moveToFolderAction: return "move it to the *specified* folder"
        case .deleteAction: return "delete it"
        case .forwardAction: return "forward it to *people or public group*"
        case .replyUsingTemplateAction: return "reply using *a specific template*"
        case .displayMessageInNewItemAlertWindowAction: return "display *a specific message* in the New Item Alert window"
        case .flagAction: return "flag message for *action in a number of days*"
        case .clearFlagAction: return "clear the Message flag"
        case .assignToCategoryAction: return "assign it to the *category* category"
        case .playSoundAction: return "play *a sound*"
        case .markImportanceAction: return "mark it as *importance*"
        case .markSensitivityAction: return "mark it as *sensitivity*"
        case .moveCopyToFolderAction: return "move a copy to the *specified* folder"
        case .notifyReadAction: return "notify me when it is read"
        case .notifyDeliveredAction: return "notify me when it is delivered"
        case .ccAction: return "Cc the message to *people or public group*"
        case .deferDeliveryAction: return "defer delivery by *a number of* minutes"
        case .performCustomActionAction: return "perform *a custom action*"
        case .netFoldersAction: return "use Net Folders"
        case .unusedAction: return "unused"
        case .stopProcessingMoreRulesAction: return "stop processing more rules"
        case .doNotSearchForCommercialOrAdultContentAction: return "do not search message for commercial or adult content"
        case .redirectAction: return "redirect it to *people or public group*"
        case .addToRelevanceAction: return "add *number* to relevance"
        case .serverReplyAction: return "have server reply using *a specific message*"
        case .forwardAsAttachmentAction: return "forward it to *people or public group* as an attachment"
        case .printAction: return "print it"
        case .startApplicationAction: return "start *application*"
        case .permanentlyDeleteAction: return "permanently delete it"
        case .runScriptAction: return "run *a script*"
        case .markAsReadAction: return "mark it as read"
        case .hiddenServerReplyAction: return "have server reply using *a specific message*"
        case .dotNetNotificationAction: return "notify me using a .NET notification"
        case .displayDesktopAlertAction: return "display a Desktop Alert"
        case .flagColorAction: return "flag message with *a colored flag*"
        case .flagForFollowUpAction: return "flag message for *follow up at this time*"
        case .clearCategoriesAction: return "clear message's categories"
        case .applyRetentionPolicyAction: return "apply retention policy: *retention policy*"
        case .nameInToBoxException: return "where my name is in the To box"
        case .sentOnlyToMeException: return "sent only to me"
        case .nameNotInToBoxException: return "where my name is not in the To box"
        case .fromException: return "from *people or public group*"
        case .sentToException: return "sent to *people or public group*"
        case .specificWordsInSubjectException: return "with *specific words* in the subject"
        case .specificWordsInBodyException: return "with *specific words* in the body"
        case .specificWordsInSubjectOrBodyException: return "with *specific words* in the subject or body"
        case .flaggedForActionException: return "flagged for *action*"
        case .importanceException: return "marked as *importance*"
        case .sensitivityException: return "marked as *sensitivity*"
        case .nameInToBoxMeetingException: return "where my name is in the To box and it is a meeting"
        case .nameNotInToBoxMeetingException: return "where my name is not in the To box and it is a meeting"
        case .assignedToCategoryException: return "assigned to *category* category"
        case .sentToAsCcException: return "sent to *people or public group* as Cc"
        case .sentToAlternateException: return "sent to *people or public group*"
        case .automaticReplyException: return "which is an automatic reply"
        case .hasAttachmentException: return "which has an attachment"
        case .withSelectedPropertiesOfDocumentOrFormsException: return "with *selected properties* of documents or forms"
        case .sizeInSpecificRangeException: return "with a size *in a specific range*"
        case .receivedInSpecificDateSpanException: return "received *in a specific date span*"
        case .nameInCcBoxException: return "where my name is in the Cc box"
        case .nameInToOrCcBoxException: return "where my name is in the To or Cc box"
        case .usesFormException: return "uses the *form name* form"
        case .specificWordsInRecipientsAddressException: return "with *specific words* in the recipient's address"
        case .specificWordsInSendersAddressException: return "with *specific words* in the sender's address"
        case .specificWordsInMessageHeaderException: return "with *specific words* in the message header"
        case .throughSpecifiedAccountException: return "through the *specified* account"
        case .senderInSpecifiedAddressBookException: return "sender is in *specified* Address Book"
        case .whichIsAMeetingInvitationOrInviteException: return "which is a meeting invitation or update"
        case .specificInfoPathFormException: return "of the *specific* form type (InfoPath)"
        case .fromRSSFeedsWithSpecifiedTextInTitleException: return "from RSS feeds with *specified text* in the title"
        case .assignedToAnyCategoryException: return "assigned to any category"
        case .fromAnyRSSFeedException: return "from any RSS feed"
        }
    }
}

public extension RuleElement {
    /// The element as Outlook's Rules Wizard words it, with its value filled in, such as "from Hugh Bellamy" or
    /// "move it to the Invoices folder". Exceptions are worded as their condition; `Rule.text` adds "except".
    var text: String {
        let template = identifier.textTemplate
        guard let start = template.firstIndex(of: "*"),
              let end = template[template.index(after: start)...].firstIndex(of: "*") else {
            return template
        }

        let placeholder = String(template[template.index(after: start)..<end])
        return String(template[..<start]) + (valueText ?? placeholder) + String(template[template.index(after: end)...])
    }

    /// The element's value in words, or nil if it has none to show.
    private var valueText: String? {
        let isAction = identifier.rawValue >= 300 && identifier.rawValue < 400
        switch parameter {
        case let parameter as AddressParameter:
            let names = parameter.recipients.compactMap { $0.displayName ?? $0.smtpAddress ?? $0.emailAddress }
            return names.isEmpty ? nil : names.joined(separator: parameter.matchAny ? " or " : " and ")
        case is StringParameter:
            let words = parameters.compactMap { ($0 as? StringParameter)?.value }
            return words.isEmpty ? nil : words.map { "'\($0)'" }.joined(separator: " or ")
        case let parameter as FlaggedForActionParameter:
            return parameter.action
        case let parameter as FlagParameter:
            switch parameter.days {
            case 0: return parameter.action
            case 1: return "\(parameter.action) in 1 day"
            default: return "\(parameter.action) in \(parameter.days) days"
            }
        case let parameter as ImportanceParameter:
            return ["Low", "Normal", "High"].element(at: parameter.rawImportance) ?? "importance \(parameter.rawImportance)"
        case let parameter as SensitivityParameter:
            return ["Normal", "Personal", "Private", "Confidential"].element(at: parameter.rawSensitivity) ?? "sensitivity \(parameter.rawSensitivity)"
        case let parameter as CategoryParameter:
            return parameter.categories.isEmpty ? nil : parameter.categories.joined(separator: isAction ? " and " : " or ")
        case let parameter as SizeParameter:
            switch (parameter.minimum, parameter.maximum) {
            case (0, 0): return nil
            case (_, 0): return "of at least \(parameter.minimum) KB"
            case (0, _): return "of at most \(parameter.maximum) KB"
            default: return "between \(parameter.minimum) KB and \(parameter.maximum) KB"
            }
        case let parameter as TimeParameter:
            var parts: [String] = []
            if parameter.hasAfter {
                parts.append("after \(RuleElement.format(parameter.after))")
            }
            if parameter.hasBefore {
                parts.append("before \(RuleElement.format(parameter.before))")
            }
            return parts.isEmpty ? nil : parts.joined(separator: " and ")
        case let parameter as FormTypeParameter:
            return parameter.name
        case let parameter as RelevanceRangeParameter:
            return "between \(parameter.minimum) and \(parameter.maximum)"
        case let parameter as AccountParameter:
            return parameter.accountName
        case let parameter as AddressBookParameter:
            return parameter.name
        case let parameter as FolderParameter:
            return parameter.folderName
        case let parameter as PathParameter:
            return parameter.path
        case let parameter as MessageParameter:
            return "'\(parameter.message)'"
        case let parameter as CustomActionParameter:
            return parameter.name
        case let parameter as DeferParameter:
            return "\(parameter.minutes)"
        case let parameter as RelevanceParameter:
            return "\(parameter.value)"
        case let parameter as TemplateParameter:
            return parameter.name
        case let parameter as ScriptParameter:
            return parameter.name
        case let parameter as FlagColorParameter:
            /// `PR_FLAG_ICON` values (spec §8.29).
            let colors = ["no", "a purple", "an orange", "a green", "a yellow", "a blue", "a red"]
            return colors.element(at: parameter.color).map { "\($0) flag" } ?? "flag colour \(parameter.color)"
        case let parameter as FlagForFollowUpParameter:
            let when: String
            switch parameter.followUp {
            case .today: when = "Today"
            case .tomorrow: when = "Tomorrow"
            case .thisWeek: when = "This Week"
            case .nextWeek: when = "Next Week"
            case .thisMonth: when = "This Month"
            case .nextMonth: when = "Next Month"
            case .noDate: when = "No Date"
            case .completed: when = "Complete"
            case nil: when = "follow-up \(parameter.rawFollowUp)"
            }
            return "\(parameter.action) \(when)"
        case let parameter as RetentionPolicyParameter:
            return parameter.name
        default:
            return nil
        }
    }

    /// A date without its time, as Outlook shows it: Outlook stores "after 26 Oct" as 23:59 on 26 Oct.
    private static func format(_ date: OleDateTime) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date.date)
    }
}

public extension Rule {
    /// The rule as Outlook's Rules Wizard describes it, one line per element: when it runs, its conditions (joined
    /// with "and"), its actions (joined with "and") and its exceptions (joined with "or"). For example:
    ///
    ///     Apply this rule after the message arrives
    ///     from Hugh Bellamy
    ///     and with 'invoice' in the subject
    ///     move it to the Invoices folder
    ///     except if it has an attachment
    var text: String {
        var lines: [String] = []

        let events: [(RuleEventFlags, String)] = [
            (.afterReceived, "after the message arrives"),
            (.afterSent, "after I send the message"),
            (.afterServerReceived, "after the server receives the message"),
        ]
        let when = events.filter { eventFlags.contains($0.0) }.map { $0.1 }
        lines.append("Apply this rule " + (when.isEmpty ? "(never)" : when.joined(separator: " or ")))

        for (index, condition) in conditions.enumerated() {
            lines.append((index == 0 ? "" : "and ") + condition.text)
        }
        for (index, action) in actions.enumerated() {
            lines.append((index == 0 ? "" : "and ") + action.text)
        }
        for (index, exception) in exceptions.enumerated() {
            lines.append((index == 0 ? "except " : "or except ") + Rule.exceptionText(exception.text))
        }
        if let reason = unparsedReason {
            lines.append("(elements not read: \(reason))")
        }

        return lines.joined(separator: "\n")
    }

    /// Turns a condition's wording into an exception's: "which has an attachment" becomes "if it has an attachment",
    /// "with 'x' in the subject" becomes "if the subject contains 'x'", and "from A" becomes "if from A".
    private static func exceptionText(_ condition: String) -> String {
        if condition.hasPrefix("which ") {
            return "if it " + condition.dropFirst("which ".count)
        }
        if condition.hasPrefix("marked as ") || condition.hasPrefix("assigned to ") || condition.hasPrefix("flagged for ") {
            return "if it is " + condition
        }
        if condition.hasPrefix("received ") {
            return "if it was " + condition
        }
        if condition.hasPrefix("uses ") {
            return "if it " + condition
        }
        if condition.hasPrefix("with a size ") {
            return "if it has a size " + condition.dropFirst("with a size ".count)
        }
        if condition.hasPrefix("with "), let range = condition.range(of: " in the ", options: .backwards) {
            let words = condition[condition.index(condition.startIndex, offsetBy: "with ".count)..<range.lowerBound]
            return "if the \(condition[range.upperBound...]) contains \(words)"
        }
        if condition.hasPrefix("with ") {
            return "if it has " + condition.dropFirst("with ".count)
        }
        if condition.hasPrefix("of the ") {
            return "if it is " + condition
        }
        if condition.hasPrefix("where ") || condition.hasPrefix("through ") {
            return condition
        }
        return "if " + condition
    }
}

private extension Array {
    func element(at index: UInt32) -> Element? {
        Int(index) < count ? self[Int(index)] : nil
    }
}
