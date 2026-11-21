# Running Outlook Rules

This document describes how Outlook runs rules on the client: when it runs them, how it tests each condition, and what each action does to a message. It is a companion to the [file format specification](Rules.md), which defines the rules themselves. Rules that the Exchange server runs are described in [Exchange server rules](ServerRules.md).

As in the format specification, a statement about an Outlook version was read from that version's code, and the addresses are in [Decompilation notes](Decompilation.md).

## Contents

* [1. When rules run](#1-when-rules-run)
  * [1.1 Cached Exchange Mode](#11-cached-exchange-mode)
* [2. Processing the rules](#2-processing-the-rules)
* [3. Condition tests](#3-condition-tests)
  * [3.1 Words](#31-words)
  * [3.2 Document properties](#32-document-properties)
  * [3.3 Junk mail](#33-junk-mail)
  * [3.4 Accounts](#34-accounts)
  * [3.5 This computer](#35-this-computer)
  * [3.6 Address books](#36-address-books)
  * [3.7 Alert E-mail](#37-alert-e-mail)
* [4. Actions](#4-actions)
  * [4.1 Follow-up flags](#41-follow-up-flags)
  * [4.2 Retention policies](#42-retention-policies)
  * [4.3 Scripts](#43-scripts)
  * [4.4 Server reply](#44-server-reply)
* [5. Errors](#5-errors)
* [6. Unsafe actions](#6-unsafe-actions)

## 1. When rules run

Every trigger first sets a **run mode**, which says what kind of message is being processed (Outlook 2003):

| Mode | Messages | Rules that match |
|---|---|---|
| `0` | A received message | Rules on received messages (event `0x1`). |
| `2` | A sent message | Rules on sent messages (event `0x4`). Outlook first saves the message. |
| `4` | Messages processed later, in Cached Exchange Mode or in a folder | Both kinds of rule. |

The event test matches a rule whose `0x0190` ("apply this rule *after the message arrives*") flags have "arrives" (`0x1`) only in modes `0` and `4`, and "sent" (`0x4`) only in modes `2` and `4` ([Rules §8.1](Rules.md#81-eventparameter)). The move and copy actions also check the message's store, but only in modes `0` and `4`.

* **Outlook 2003**'s Cached Exchange Mode trigger passes `4` ([§1.1](#11-cached-exchange-mode)), one trigger passes `2`, and the others `0`.
* **Outlook 2007, 2010 and 2013** have four triggers: new mail (mode `0`, **[Inferred]** in Outlook 2007), a sent message (`2`), deferred action messages (`0`, or `4` when the cleanup routine has marked them, [Server rules §4](ServerRules.md#4-client-only-parts-and-deferred-actions)), and messages already in a folder (`4`). The folder run goes through a folder and its subfolders, 500 messages at a time. **[Inferred]** It is used by Run Rules Now and by "Run this rule now on messages already in the current folder" on the wizard's last page.
* Outlook 97–2002 weren't traced.

### 1.1 Cached Exchange Mode

* **Outlook 2003** exports a function, `HrTriggerCachedExchangeRules`, that Office 2003's Exchange store provider (`EMSMDB32.DLL`) calls to run the client rules on newly arrived items in the default store's Inbox. Outlook runs the job on its main thread. The store provider also gets this computer's 33-character ID from Outlook's `HrGetRulesMachineID`, and uses it to restrict the server's rules table to three providers: Outlook's own rules (`RuleOrganizer`), the Out of Office Assistant's (`MSFT:TDX OOF Rules`) and the Inbox Assistant's (`MSFT:TDX Rules`). For each provider it matches the plain name as a prefix, or the name (`RuleOrganizer2` for Outlook's rules) followed by the computer ID exactly. The rules themselves are stored and read exactly as in online mode.
* **Outlook 2007** no longer exports the trigger, but still exports `HrGetRulesMachineID`. It already handles cached mode as Outlook 2010 does.
* **Outlook 2010 and 2013** export neither function and have no separate trigger for Cached Exchange Mode. Their cached-mode work is in their handling of deferred action messages ([Server rules §4](ServerRules.md#4-client-only-parts-and-deferred-actions)).

## 2. Processing the rules

Outlook goes through the rules in list order. For each rule (Outlook 2003):

1. The run stops if it was aborted or a rule stopped processing.
2. Rules Outlook can't run are skipped: rules newer than its own version, which it keeps unparsed ([Rules §5.5](Rules.md#55-rules-from-newer-versions)), and rules it has marked in memory (not in the file's Flags).
3. A rule that can run entirely on the server ([Server rules §1](ServerRules.md#1-which-rules-run-on-the-server)) is normally left to it. Such a rule is skipped while Outlook is online. In Outlook 2010 and 2013 "online" is the MAPI offline state's `MAPIOFFLINE_STATE_ONLINE` bit; in Outlook 2003 it is **[Inferred]** the same. When Outlook is offline, the rule runs on the client only if it moves or copies the message (`0x012C` or `0x0139`). Outlook 2002–2013 have this check; Outlook 98 and 2000 don't have it in this form.
4. Disabled rules are skipped.
5. The conditions and exceptions are tested in order, and testing stops at the first that fails, so they are combined with AND ([§3](#3-condition-tests)). If they all pass, the actions run in order ([§4](#4-actions)), with RunError and Enabled updated after each ([Rules §5.1](Rules.md#51-ruleheader)).
6. After the rule, the run stops if one of its actions set the stop flag, and otherwise moves to the next rule. "Stop processing more rules" (`0x0142`) and, in Outlook 2003 and 2007, the Net Folders action (`0x0141`) set it. So do "delete it" and "permanently delete", which also mark the message as gone, so deleting a message always ends processing.

When the run finishes, Outlook saves the rules if any action failed and reported its own error, as the script and redirect actions do, so that the save records the changed RunError.

Outlook 2010 and 2013 run the same steps.

## 3. Condition tests

Each condition is a test on the message being processed. Exceptions are tested as their condition with the result inverted. Outlook 2003's tests:

| Element | Test |
|---|---|
| `0x00C8` ("where my name is in the To box"), `0x00CA` ("where my name is not in the To box"), `0x00E2` ("where my name is in the Cc box"), `0x00E3` ("where my name is in the To or Cc box") | Read from `PR_MESSAGE_TO_ME`, `PR_MESSAGE_CC_ME` and `PR_MESSAGE_RECIP_ME`. |
| `0x00C9` sent only to me | Its own test. |
| `0x00CB` from | The sender, against the parameter's addresses. |
| `0x00CC`, `0x00DB` sent to | Matches if any To recipient or any Cc recipient matches. |
| `0x00DA` sent to as Cc | Cc recipients only. |
| `0x00CD`, `0x00CE` words in subject, body | The words of [§3.1](#31-words), on `PR_SUBJECT` or on the body. |
| `0x00CF` words in subject or body | The subject first, then the body. |
| `0x00D4` ("where my name is in the To box and it is a meeting"), `0x00D5` ("where my name is not in the To box and it is a meeting") | "To me" (or not) and a meeting message class. |
| `0x00D7` assigned to category | The parameter's categories, split at `;`, against the message's categories. |
| `0x00DC` automatic reply | `PR_MESSAGE_CLASS` is `IPM.Note.Rules.OofTemplate.Microsoft`, ignoring case. |
| `0x00DF` document properties | [§3.2](#32-document-properties). |
| `0x00E5` ("with *specific words* in the recipient's address"), `0x00E6` ("with *specific words* in the sender's address"), `0x00E8` ("with *specific words* in the message header") | Words in the recipients' addresses, the sender's address, and `PR_TRANSPORT_MESSAGE_HEADERS`. |
| `0x00E9`–`0x00EC` junk mail | Never match. |
| `0x00EE` account | [§3.4](#34-accounts). |
| `0x00EF` on this computer only | The parameter's GUID equals this computer's ID. |
| `0x00F0` sender in address book | [§3.6](#36-address-books). |
| `0x00F1` meeting invitation or update | `PR_MESSAGE_CLASS` starts with `IPM.Schedule.Meeting.Request` or `IPM.Schedule.Meeting.Canceled`, ignoring case: the same test as the server form. |
| `0x00F3` Alert E-mail | `PR_TRANSPORT_MESSAGE_HEADERS` contains the text after the alert name's last U+0001 ([§3.7](#37-alert-e-mail)). |
| `0x0064` ("for each *message*"), `0x0190` ("apply this rule *after the message arrives*") | The item type and event are tested too. |

**Other versions.**

* **Outlook 97**'s evaluator has a test for every element in its table, and for the four conditions in [Rules §7.6](Rules.md#76-identifiers-outside-the-tables). "Is a meeting" means `IPM.Appointment` or `IPM.Schedule.Meeting.Request`, and "is a task" means `IPM.Task` or `IPM.TaskRequest`. "Sent directly to me" reads `PR_MESSAGE_TO_ME`, and "my name in the Cc box" reads `PR_MESSAGE_CC_ME`. The item type (`0x0064`) always matches.
* **Outlook 98** has the same design. `0x00D1`, `0x00D6`, `0x00D8`, `0x00D9` and `0x00DD` have no test, `0x00E9` ("from senders on my *Exception List*") never matches, and `0x00EA`–`0x00EC` use the junk-mail test ([§3.3](#33-junk-mail)). Document properties are matched with MatchIfMissing pairs ([Rules §8.9.1](Rules.md#891-matchifmissing)).
* **Outlook 2000** has the same design and tests, plus relevance (`0x00ED`).
* **Outlook 2002** fetches the message body only if a rule needs it: word conditions on the body (`0x00CE`, `0x00CF` and their exceptions) or the junk-mail conditions (`0x00E9`–`0x00EC`). It tests `0x00EA`–`0x00EC` with the junk-mail test, which Outlook 2003 replaced with "never matches". In both, `0x00D1`, `0x00D6`, `0x00D8`, `0x00D9`, `0x00DD` and `0x00E9` ("from senders on my *Exception List*") count as no match.
* **Outlook 2007** adds tests for its new conditions:
  * `0x00F4` InfoPath form type: the message class against each parameter's message class.
  * `0x00F5` RSS feed name: the message class starts with `IPM.Post.Rss`, the "Enable rules on all RSS Feeds" setting is on ([Rules Wizard §3](RulesWizard.md#3-dialogs-by-version)), and the feed's subscription name (the PostRss named property `0x8906`) equals one of the parameter's strings, ignoring case. Despite the UI text, this is the feed's name, not the item's title.
  * `0x00F6` any category: the message's `Keywords` has at least one value.
  * `0x00F7` any RSS feed: the message class starts with `IPM.Post.Rss` and the RSS setting is on.
* **Outlook 2010** has the same tests as Outlook 2007. `0x00E7` (Net Folders) and `0x00E9`–`0x00EC` share a test that always fails. Outlook 2010 RTM still has a test for `0x00ED` ("with a relevance *in a specific range*").
* **Outlook 2013** is the same as Outlook 2010, except that `0x00ED` ("with a relevance *in a specific range*") now shares the failing test.

### 3.1 Words

How Outlook matches a word condition ([Rules §8.3](Rules.md#83-wordparameter)). In every version the match is a substring search that ignores case and word boundaries:

* **Outlook 97** matches the whole phrase as a substring of the subject or body, ignoring case.
* **Outlook 98** lowercases the text and the word and searches for the word in the text.
* **Outlook 2002–2013** match if any parameter occurs anywhere in the text. They compare upper-cased characters through Office's string search; Outlook 2010 and 2013 slide the word along the text and compare it at each position. An empty or missing subject or body never matches (Outlook 2003, 2007 and 2010). For "subject or body" (`0x00CF`), Outlook tests the subject first, then the body (Outlook 2003 and 2010).

### 3.2 Document properties

A document property condition ([Rules §8.9](Rules.md#89-formparameter)) compares each property of the message with the values in its DocumentProperty record. How Outlook 2003 compares each type:

* Strings (`PT_UNICODE`): "contains" and "does not contain" use `wcsstr`, which is case-sensitive; "is exactly" uses `_wcsicmp`, which ignores case. A multi-valued string (`PT_MV_UNICODE`, for example Keywords) is joined with `;` first.
* Integers: `PT_I2` properties are compared with NumberValue1 and `PT_LONG` properties with NumberValue2, as signed numbers.
* Booleans: BoolMatch `0` matches a non-zero value and `1` matches zero.
* Dates (`PT_SYSTIME`): DateMatch `0` matches dates before DateValue and `1` dates after it.

Which match field applies to each type is in [Rules §8.9](Rules.md#89-formparameter).

Outlook 2007 and 2010 compare the same way. Both handle `PT_I2`, `PT_LONG`, `PT_ERROR`, `PT_BOOLEAN`, `PT_UNICODE`, `PT_SYSTIME` and `PT_MV_UNICODE`. A `PT_ERROR` value, which is what Outlook gets for a property the message doesn't have, records that the property is missing, for MatchIfMissing (Outlook 2010). Outlook 2007's branches were checked only for "contains", "is exactly" and integers. Outlook 2013's matcher reads MatchIfMissing in the same way; its branches weren't compared one by one.

### 3.3 Junk mail

Outlook 98–2002 don't read the parameter. For `0x00EA` (older form of junk senders) and `0x00EB` ("suspected to be junk e-mail or from *Junk Senders*") they check that the message's property `0x1083` (`PT_LONG`, one of the properties Outlook fetches for every message it runs rules on) is `1`, and for `0x00EC` ("containing adult content or from *Adult Content Senders*") that it is `2`. `0x00E9` ("from senders on my *Exception List*") never matches. Outlook reads property `0x1083` from the message with `GetProps`, so it is a property stored on the message. No code in `OUTLLIB.DLL` or `OUTLAS.DLL` writes it: its tag appears only in Outlook's list of properties to fetch. What sets it was not found in these binaries. Outlook 2003–2013 never match any of the four.

### 3.4 Accounts

Accounts are matched by ID, not by name. Outlook 2003 reads the message's account from the named properties `0x8580` (account name) and `0x8581` (account stamp) in `PSETID_Common` (`{00062008-0000-0000-C000-000000000046}`), looks the account up through Outlook's account manager, and compares the account's property `0x00030003` with the number the AccountParameter gives. Outlook 2010 and 2013 do the same. Not traced in Outlook 2000, 2002 or 2007.

### 3.5 This computer

"On this computer only" (`0x00EF`) matches when the parameter's Stamp, a GUID ([Rules §8.16](Rules.md#816-profilestampparameter)), equals this computer's ID (Outlook 2003–2013).

### 3.6 Address books

Outlook 2003 tests the condition by taking the sender's address (`PR_SENDER_EMAIL_ADDRESS`), opening the chosen container, and looking for an entry with that `PR_EMAIL_ADDRESS` and `PR_ADDRTYPE`. Outlook 2010 and 2013 do the same with the Unicode properties: `PR_SENDER_EMAIL_ADDRESS_W` (`0x0C1F001F`), `PR_EMAIL_ADDRESS_W` and `PR_ADDRTYPE_W`. Not traced in Outlook 2002 or 2007.

### 3.7 Alert E-mail

For "which is an *Alert E-mail*" (`0x00F3`), Outlook splits the parameter's Name ([Rules §8.18](Rules.md#818-alertparameter)) at the last U+0001. It shows the part before it as the alert's name, and looks for the part after it in the message's transport headers (`PR_TRANSPORT_MESSAGE_HEADERS`) (Outlook 2003–2013). On the client, Outlook 2010 and 2013 use `wcsstr`, which is case-sensitive; on the server, Outlook 2003 uses a substring test that ignores case ([Server rules §3](ServerRules.md#3-server-forms-of-elements)).

## 4. Actions

What each action does when Outlook runs it (Outlook 2003):

| Action | Behaviour |
|---|---|
| `0x012C` move, `0x0139` ("move a copy to the *specified* folder") copy | Move or copy the message; one handler for both. |
| `0x012D` delete | Delete the message, and stop processing ([§2](#2-processing-the-rules)). |
| `0x014A` permanently delete | Separate from "delete it"; also stops processing. |
| `0x012E` forward, `0x0147` ("forward it to *people or public group* as an attachment") forward as attachment | Forward the message. |
| `0x0144` redirect | Its own handler. |
| `0x012F` reply using template, `0x0146` ("have server reply using *a specific message*") server reply, `0x014D` ("have server reply using *a specific message*") | One handler for all three. |
| `0x0130` alert window | Show the message in the New Item Alert window. |
| `0x0131` flag | Flag the message, computing the due date. |
| `0x0132` clear flag | Clear the flag. |
| `0x0133` category | Assign the categories. |
| `0x0136` play a sound | Play the sound through Office. |
| `0x0137` importance, `0x0138` ("mark it as *sensitivity*") sensitivity | Set the property. |
| `0x013A` read receipt, `0x013B` ("notify me when it is delivered") delivery receipt | Request the receipt. |
| `0x013C` Cc | Add recipients with `PR_RECIPIENT_TYPE`. |
| `0x013E` defer delivery | Compute the delivery time. |
| `0x013F` custom action | Run the custom action. |
| `0x0145` add to relevance | Its own handler. |
| `0x0148` print | Print the message. |
| `0x0149` start application | Its own handler. |
| `0x014B` run a script | Open the message as an Outlook item and call the VBA procedure ([§4.3](#43-scripts)). |
| `0x014C` mark as read | Mark the message read. |
| `0x014F` Desktop Alert | Show Outlook's New Mail Desktop Alert for the message. When Outlook shows it for new mail, it first checks the "Display a New Mail Desktop Alert" option; the rule shows it whatever that option says. |
| `0x0150` coloured flag | Set `PR_FLAG_ICON` to the colour and `PR_FLAG_STATUS` to `2` (flagged). If the message has no flag text, also set the default flag text. Colour `0` instead marks the colour for removal, as "clear the Message flag" does. This confirms that [Rules §8.29](Rules.md#829-flagcolorparameter)'s Color is a `PR_FLAG_ICON` value. |
| `0x0141` Net Folders, `0x0142` ("stop processing more rules") stop processing | Set the run's stop flag. |
| `0x0143` | Nothing. |
| `0x0134`, `0x0135`, `0x013D`, `0x0140` (hidden, no text), `0x014E` ("notify me using a .NET notification") | No handler. Outlook reports an error for the rule. |

The actions collect their changes to the message and save them together.

**Other versions.**

* **Outlook 98** has a handler for each action from `0x012C` ("move it to the *specified* folder") to `0x0142`. Copy (`0x0139`) uses the same handler as move, "play a sound" (`0x0136`) has its own, and "stop processing more rules" (`0x0142`) is handled by the loop. `0x0134`, `0x0135`, `0x013D` and `0x0140` (hidden, no text) have no handler, as in Outlook 2003.
* **Outlook 2000**: a failing action sets RunError and turns the rule off ([Rules §5.1](Rules.md#51-ruleheader)). `0x0141` hands the message to Net Folders ([Rules §7.4](Rules.md#74-actions)).
* **Outlook 2007** adds the follow-up flag (`0x0151`, [§4.1](#41-follow-up-flags)) and "clear message's categories" (`0x0152`), which removes the message's `Keywords`. `0x014D` ("have server reply using *a specific message*") still runs like "reply using a template", `0x014E` ("notify me using a .NET notification") still has no handler, and `0x0141` (Net Folders) and `0x0142` ("stop processing more rules") still set the stop flag.
* **Outlook 2010** adds the retention policy (`0x0153`, [§4.2](#42-retention-policies)). `0x0141` (Net Folders) no longer stops processing: like `0x0143` ("do not search message for commercial or adult content"), it does nothing. `0x014D` ("have server reply using *a specific message*") now has no handler, like `0x0134`, `0x0135`, `0x013D`, `0x0140` (hidden, no text) and `0x014E` ("notify me using a .NET notification"). The custom action (`0x013F`) still runs. "Stop processing more rules" sets the stop flag, and "delete it" also marks the message as deleted and stops.
* **Outlook 2013** no longer runs the custom action: `0x013F` ("perform *a custom action*") joins the actions without a handler. "Add to relevance" (`0x0145`) does nothing, like `0x0141` (Net Folders) and `0x0143` ("do not search message for commercial or adult content"). The other actions run as in Outlook 2010.

### 4.1 Follow-up flags

What "flag message for follow up" (`0x0151`, [Rules §8.27](Rules.md#827-flagforfollowupparameter)) does (Outlook 2007–2013):

* **Every value:**
  * the flag text (PidLidFlagRequest) is set from Action;
  * `PR_TODO_ITEM_FLAGS` is set to `1`;
  * the to-do title (PidLidToDoTitle) is set from the subject;
  * the to-do ordinal date and sub-ordinal are set.
* **`10` (complete):**
  * `PR_FLAG_STATUS` = `1` (complete);
  * task status = `2` (complete), percent complete = 100% and task complete = true;
  * date completed = now.
* **Any other value:**
  * `PR_FLAG_STATUS` = `2` (flagged) and `PR_FLAG_ICON` = `6` (red).
  * `7` (no date) removes the start and due dates (PidLidCommonStart/End and the task start and due dates) and resets the task's status, percent complete and completion.
  * Values `1`–`6` look up a start and due date rule in a table indexed by FollowUp, so `5` and `6` are also valid, though the samples use only `1`–`4`. **[Inferred]** `5` and `6` are this month and next month, from their table entries.

### 4.2 Retention policies

"Apply retention policy" (`0x0153`) sets the message's `PR_POLICY_TAG` (`0x30190102`) to the parameter's PolicyId, and `PR_RETENTION_PERIOD` (`0x301A0003`) to the policy's retention period. On the server it is two `OP_TAG` actions for the same two properties ([Server rules §3](ServerRules.md#3-server-forms-of-elements)). (Outlook 2010 and 2013, [Rules §8.28](Rules.md#828-retentionpolicyparameter).)

### 4.3 Scripts

"Run a script" (`0x014B`) opens the message as an Outlook item, passes it to the procedure as its single argument, and calls the VBA procedure that the parameter's Name names. If that fails, Outlook reports an error quoting Name. Outlook uses Name whole, and never the parameter's second string, Function. (Outlook 2002–2013, [Rules §8.26](Rules.md#826-scriptparameter).)

### 4.4 Server reply

When Outlook runs "have server reply using *a specific message*" (`0x0146`) itself, rather than leaving it to the server, it uses its "reply using a template" handler: Outlook 2000, 2002, 2003, 2010 and 2013 (not traced in Outlook 2007).

## 5. Errors

When an action fails, Outlook 2002 and later turn the rule off, set its RunError ([Rules §5.1](Rules.md#51-ruleheader)), and add it to the "Rules in Error" window, which lists the client rules that failed while running. Outlook 2010 posts the update to its main thread when needed. An action that has no handler reports an error for its rule.

How RunError ([Rules §5.1](Rules.md#51-ruleheader)) is set has changed over time:

* **Outlook 97** gives new rules `0`. It copies and saves the field but never reads it.
* **Outlook 98** runs the actions one by one. After each, it sets RunError to the action's HRESULT, so a failure stores an error code such as `0x80004005` rather than `1`, and sets Enabled to whether the action succeeded. A failure also shows an error naming the rule. The remaining actions still run, and a later success resets both fields.
* **Outlook 2000**: when an action of a client rule fails, Outlook sets RunError to `1`, turns the rule off (Enabled = `0`) and shows an error message naming the rule. A rule that runs without error gets `0`.
* **Outlook 2002, 2003 and 2007** run the actions one by one and, after each, set RunError to whether that action failed. When an action fails they also turn the rule off and add it to the "Rules in Error" window instead of showing a message. Because the field is set after every action, a later action that succeeds sets it back to `0`, though the rule stays off: Outlook doesn't turn a rule back on when it later runs without error.
* **Outlook 2010 and 2013** do the same, but no longer keep RunError as a separate number. Like Enabled, it is a bit of the rule's state in memory. Loading sets the bit for any non-zero value, and saving writes `1` or `0`. So an older error code, such as the `0x80004005` Outlook 98 stores, is written back as `1`.
* **Outlook 2010 updates** (14.0.7261) also mark a rule as failed when it contains an element that the update no longer allows ([§6](#6-unsafe-actions)): such a rule is saved with RunError `1`, and gets the RunError bit when it is loaded.

## 6. Unsafe actions

Later updates to Outlook 2010 (14.0.7261.5000 was studied) added a registry value, `EnableUnsafeClientMailRules`, under Outlook's `Security` key. Outlook reads it once. Unless it is non-zero, Outlook refuses "perform a custom action" (`0x013F`), "start application" (`0x0149`) and "run a script" (`0x014B`), as well as relevance (`0x00ED`, `0x0145`), which Outlook 2010 RTM already refuses. The wizard won't use a refused element. A rule that contains one is saved with RunError `1`, and gets the RunError bit when it is loaded ([Rules §5.1](Rules.md#51-ruleheader)). The fields written are unchanged.

Outlook 2013 RTM and its update 15.0.4517.1509 don't have the value. It came with later updates, as in Outlook 2010.
