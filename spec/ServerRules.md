# Exchange Server Rules

This document describes how Outlook shares rules with an Exchange server: which rules it uploads, what the server copy looks like, how the server hands work back to Outlook, and how Outlook reads server rules back into its own rules. It is a companion to the [file format specification](Rules.md). How Outlook runs rules itself is in [Running rules](Running.md).

As in the format specification, a statement about an Outlook version was read from that version's code, and the addresses are in [Decompilation notes](Decompilation.md).

## Contents

* [1. Which rules run on the server](#1-which-rules-run-on-the-server)
* [2. Uploading rules](#2-uploading-rules)
* [3. Server forms of elements](#3-server-forms-of-elements)
* [4. Client-only parts and deferred actions](#4-client-only-parts-and-deferred-actions)
* [5. Reading server rules back](#5-reading-server-rules-back)
* [6. Client and server rules conflict](#6-client-and-server-rules-conflict)
* [7. Inbox Assistant and Out of Office rules](#7-inbox-assistant-and-out-of-office-rules)
* [8. Rules Outlook can't show](#8-rules-outlook-cant-show)

## 1. Which rules run on the server

A rule can run on the Exchange server only if all three of these hold (Outlook 97):

* it has at least one action;
* none of its elements is client-only ([Rules Wizard §1](RulesWizard.md#1-element-definitions)); and
* it doesn't run "after I send the message" (event flag `0x4`).

Otherwise Outlook 97 warns that the rule "is a client-only rule, and will process only when Outlook is running". From Outlook 98 a rule with client-only parts still goes to the server, which hands the client-only parts back to Outlook ([§4](#4-client-only-parts-and-deferred-actions)). Outlook 2003 and later use the same three tests to decide which rules the server can run entirely by itself ([Running §2](Running.md#2-processing-the-rules)).

## 2. Uploading rules

Outlook writes each rule to the Inbox's server rules table as a MAPI rule ([MS-OXORULE](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxorule)) with these properties (Outlook 98):

* `PR_RULE_SEQUENCE`, from a running counter;
* `PR_RULE_STATE`, with `ST_EXIT_LEVEL` added when the rule stops processing;
* `PR_RULE_CONDITION` and `PR_RULE_ACTIONS` ([§3](#3-server-forms-of-elements));
* `PR_RULE_PROVIDER`, `PR_RULE_LEVEL` and `PR_RULE_NAME`;
* `PR_RULE_PROVIDER_DATA`, laid out as follows.

| Offset | Size | Field |
|---|---|---|
| `0x00` | 4 | Version: `1`, or the version the serialized rule that follows was written with: `970812` from Outlook 98, the rule's own stamp (for example `1000000`) from Outlook 2002. |
| `0x04` | 4 | `0` before Outlook 2002. From Outlook 2002, the rule's ServerRuleId ([Rules §5.1](Rules.md#51-ruleheader)). |
| `0x08` | 8 | A timestamp (OLE date). |
| `0x10` | variable | Versions other than 1 only: the whole rule serialized in this file format (a RuleHeader and its elements, [Rules §5](Rules.md#5-rule)), in the layout of that version. Outlook 98 and 2002 embed it when the rule has parts the server can't run. The property's size is `0x18` + the rule's length, so 8 zero bytes follow the rule. |
| `0x18` | 4 | Version 1 only, when the rule's Flags are non-zero: the Flags. The property is then `0x1C` bytes; otherwise `0x18`. |

From Outlook 2002 the provider data embeds the rule, Flags included, and offset 0 holds the embedded rule's own version stamp. Outlook 2002 sends `PR_RULE_ID` when it knows it.

**Provider name.** `PR_RULE_PROVIDER` is `RuleOrganizer`, followed by `2` when the rule's version is 1000000 or later (Outlook 2002–2013). For "on this computer only" (`0x00EF`), the GUID of that condition follows as 32 uppercase hex digits ([Rules §8.16](Rules.md#816-profilestampparameter)). When reading the server's rules, Outlook treats any provider that starts with `RuleOrganizer` as its own and compares the machine ID. The Inbox Assistant's rules use the provider `MSFT:TDX Rules`, and the Out of Office Assistant's `MSFT:TDX OOF Rules` ([§7](#7-inbox-assistant-and-out-of-office-rules)).

**Timestamp.** Each upload sets the provider-data timestamp to the current local time and then stores that same value as the footer Timestamp ([Rules §6](Rules.md#6-rulesfooter)) (Outlook 2002).

**Bookkeeping.** After writing a rule, Outlook sets its ServerRule field, and its ServerRuleId when it is new ([Rules §5.1](Rules.md#51-ruleheader)). A rule whose version is newer than Outlook's own isn't uploaded. When the server has no room, Outlook 98 deactivates the rules that failed to upload (and Outlook 97 sets ServerRulesOutOfDate, [Rules §4.4](Rules.md#44-server-settings)).

**Recording the upload.**

**ServerRule** ([Rules §5.1](Rules.md#51-ruleheader)). Outlook 97 serializes the rule and writes `PR_RULE_PROVIDER_DATA`, `PR_RULE_STATE` and the other server-rule properties through MAPI, then sets this field to `1` ([§2](#2-uploading-rules)). It is cleared again if saving fails or the server rules are reset. Every later version, up to Outlook 2013, reads and writes the field in the same place, and changes it only in the code for server rules:

* it sets `1` once a rule's server copy has been written;
* it sets `0` when that fails, or when the rule isn't uploaded, for example because its version is newer than Outlook's own;
* it resets every rule to `0` before the server rules are rebuilt;
* it sets `1` on a rule it rebuilds from a server rule ([§5](#5-reading-server-rules-back)), Outlook 2000 and later. Outlook 2000 also enables the rule there when the server rule is enabled, and Outlook 2002 does so for rules it didn't create.

Outlook 2003 also reads the field in one other place. When the junk-mail options or the Download Options dialog save their own special rule, Outlook keeps the stored rule unchanged if its ServerRule and Enabled match the new one. Otherwise it replaces the rule and marks the rules as changed.

**ServerRuleId** ([Rules §5.1](Rules.md#51-ruleheader)). When Outlook 2002 first saves a rule to the server, it gives it the next number from a counter. The counter isn't stored anywhere: when Outlook reads the server's rules, it sets the counter to the highest ID found at offset 4 of their provider data ([§2](#2-uploading-rules)). Outlook stores the number at that offset of the rule's own `PR_RULE_PROVIDER_DATA` too, and uses it to match local rules with server rules. Importing a rules file clears it. Outlook 2003–2013 work the same way: a rule with ServerRuleId `0` gets the next number when its server rule is built, importing clears the field, and reading the server's rules resets the counter to `0` and raises it to the highest ID. Outlook 2010 and 2013 also use ServerRuleId to match a deferred action message to its rule ([§4](#4-client-only-parts-and-deferred-actions)).

**This computer's ID.** A rule with "on this computer only" ([Rules §8.16](Rules.md#816-profilestampparameter)) carries the computer's ID to the server:

* **Outlook 2002**: when it uploads such a rule to Exchange, it appends this GUID to the rule's `PR_RULE_PROVIDER` as 32 uppercase hex digits. A deferred action from that rule is then handled only on the machine whose ID matches ([§4](#4-client-only-parts-and-deferred-actions)).
* **Outlook 2003**: the Exchange store provider uses this computer's ID to pick out its rules in Cached Exchange Mode ([Storage §1](Storage.md#1-the-rules-message)).
* **Outlook 2007–2013** build the provider name in the same way: `RuleOrganizer`, then `2` if the rule's version is 1000000 or later, then the GUID as 32 hex digits. Outlook 2010's rules list marks a rule whose GUID isn't this computer's.
* Outlook 2007 still exports `HrGetRulesMachineID`, which gives this computer's ID to other components. Outlook 2010 no longer does (its only rules export is `HrImportRules`), and Outlook 2013 exports no rules functions at all.

**Server settings.** The rules header records how Outlook 97–2000 keep the server up to date ([Rules §4.4](Rules.md#44-server-settings)):

* **ServerRulesOutOfDate** is set when the rules or options change, or when an upload fails for lack of server space, and cleared after a successful upload. When updates are automatic, Outlook uploads at startup if it is set (Outlook 97).
* **ServerUpdateMode** is the "Update server" setting of the Options dialog in Outlook 97, 98 and 2000, which also has an Update Now button: `1` = Manually (only when the user clicks "Update Now"), `2` = Automatically. Switching from Manually to Automatically triggers an immediate upload. `0` means not set, as written by Outlook 2002 and later.

## 3. Server forms of elements

Each condition becomes a MAPI restriction and each server action a MAPI action (Outlook 2002). Exceptions use the restriction of their matching condition ([Rules §7.5](Rules.md#75-exceptions)), wrapped in `RES_NOT`. The rule's restriction is `RES_AND` of every condition and negated exception; a rule with just one becomes that restriction alone. In Outlook 98, a rule with no condition gets a restriction that matches every message: `PR_MESSAGE_CLASS` exists.

| Element | Server form |
|---|---|
| `0x00C8` sent directly to me | `PR_MESSAGE_TO_ME` = true |
| `0x00C9` sent only to me | `PR_MESSAGE_TO_ME` = true, with tests on `PR_DISPLAY_TO` and `PR_DISPLAY_CC` |
| `0x00CA` my name is not in the To box | `PR_MESSAGE_TO_ME` = false |
| `0x00CB` from | sender restriction (uses `PR_SENDER_NAME`) |
| `0x00CC` sent to | subrestriction on `PR_MESSAGE_RECIPIENTS` (uses `PR_DISPLAY_NAME`) |
| `0x00CD`, `0x00CE`, `0x00E8` words in subject, body, header | content restriction (substring, ignore case) on `PR_SUBJECT`, `PR_BODY`, `PR_TRANSPORT_MESSAGE_HEADERS` |
| `0x00CF` words in subject or body | `PR_SUBJECT` or `PR_BODY` |
| `0x00D0` flagged for action | `PR_FLAG_STATUS` |
| `0x00D2`, `0x00D3` importance, sensitivity | `PR_IMPORTANCE`, `PR_SENSITIVITY` = value |
| `0x00D4`, `0x00D5` meeting conditions | `PR_MESSAGE_CLASS` and `PR_MESSAGE_TO_ME` |
| `0x00DC` Out of Office message | `PR_MESSAGE_CLASS` (Outlook 2013: a content restriction that ignores case) |
| `0x00DE` has an attachment | `PR_MESSAGE_FLAGS` |
| `0x00E0` size | `PR_MESSAGE_SIZE` range |
| `0x00E1` received date | `PR_MESSAGE_DELIVERY_TIME` range |
| `0x00E2` my name is in the Cc box | `PR_MESSAGE_CC_ME`, `PR_MESSAGE_RECIP_ME`, `PR_MESSAGE_TO_ME` |
| `0x00E3` my name is in the To or Cc box | `PR_MESSAGE_RECIP_ME` = true |
| `0x00E4` uses form | `PR_MESSAGE_CLASS` |
| `0x00E6` words in sender's address | `PR_SENDER_SEARCH_KEY` (substring) |
| `0x00E7` Net Folders | `PR_SUBJECT` begins with `#NET FOLDERS#`; also stops processing more rules |
| `0x00F1`, `0x0216` meeting invitation or update (Outlook 2003) | `RES_OR` of two content restrictions on `PR_MESSAGE_CLASS`, prefix and ignore case: `IPM.Schedule.Meeting.Request` and `IPM.Schedule.Meeting.Canceled` |
| `0x00F3` Alert E-mail (Outlook 2003) | Content restriction on `PR_TRANSPORT_MESSAGE_HEADERS`, substring and ignore case, for the part of the alert's name after its last U+0001 |
| `0x00F6`, `0x021A` any category (Outlook 2007) | `RES_EXIST` on the `Keywords` named property in `PS_PUBLIC_STRINGS` (`PT_MV_UNICODE`) |
| `0x00F5`, `0x00F7`, `0x0219`, `0x021B` RSS (Outlook 2007) | A placeholder that never matches on the server: `PR_MESSAGE_CLASS` equal to the empty string. RSS items only arrive on the client. |
| `0x012C` move to folder | `OP_MOVE` |
| `0x012D` delete | `OP_MOVE` to Deleted Items, and stops processing more rules |
| `0x012E` forward | `OP_FORWARD` |
| `0x0139` copy to folder | `OP_COPY` |
| `0x0142` stop processing more rules | `ST_EXIT_LEVEL` in `PR_RULE_STATE` |
| `0x0144` redirect | `OP_FORWARD` with flags `3` (preserve sender, don't change the message) |
| `0x0146` have server reply | `OP_REPLY` with the template message |
| `0x0147` forward as attachment | `OP_FORWARD` with flag `4` (as attachment) |
| `0x0152` clear message's categories (Outlook 2007) | `OP_TAG` on the `Keywords` named property in `PS_PUBLIC_STRINGS`, with an empty value |
| `0x0153` apply retention policy (Outlook 2010) | Two `OP_TAG` actions, setting `PR_POLICY_TAG` to the policy GUID and `PR_RETENTION_PERIOD` to the period |

These have no server form: the conditions `0x00D1`, `0x00D7` (category), `0x00DA`, `0x00DB`, `0x00DD`, `0x00DF` (document properties), `0x00E5` (words in the recipient's address) and every condition from `0x00E9` on except those listed above, their exceptions, and every other action.

**By version.** Outlook 98 already has the same conditions without a server form as Outlook 2002, and sends only move (`0x012C`), delete (`0x012D`), forward (`0x012E`), copy (`0x0139`) and stop processing (`0x0142`) as actions. Outlook 2000 and 2002 add redirect, server reply and forward as attachment. Outlook 2003 adds the meeting and Alert E-mail conditions, Outlook 2007 the category and RSS conditions and "clear message's categories", and Outlook 2010 the retention policy. The server-rule code also accepts identifiers that no definition table has ([Rules §7.6](Rules.md#76-identifiers-outside-the-tables)).

**Identifiers outside the definition tables.** The code that builds server rules and runs rules also has cases for identifiers that no definition table has ([Rules §7.6](Rules.md#76-identifiers-outside-the-tables)):

* the conditions `0x00D1`, `0x00D6`, `0x00D8`, `0x00D9` and `0x00DD`. Outlook 98, 2000 and 2003 send `0x00D6` and `0x00D8` to the server as "from", and Outlook 98 and 2003 send `0x00D9` as "words in the body" (Outlook 2000 has a separate case for it). Outlook 98, 2002 and 2003 have no client test for any of the five ([Running §3](Running.md#3-condition-tests));
* the exceptions `0x0202`, `0x0204` and `0x0205` (Outlook 2003's server-rule code);
* the actions `0x0134`, which the server-rule code of Outlook 98–2013 treats as move, and `0x0135`, treated as forward. Neither has a client handler;
* the action `0x013D`, which Outlook 98 makes when it converts an Inbox Assistant rule whose action it can't express ([§7](#7-inbox-assistant-and-out-of-office-rules)). It has no handler either.

Rebuilding a rule from a server rule can also ask for `0x00DD` ([§5](#5-reading-server-rules-back)), which then fails.

## 4. Client-only parts and deferred actions

A rule with client-only parts still goes to the server, which hands each message it matches back to Outlook:

* **Outlook 98** marks a rule as needing the client when it has a client-only element, or no action the server can carry out. Client-only conditions are `0x00D7`, `0x00DD`, `0x00DF`, `0x00E5` and `0x00E9`–`0x00EC` (and the exceptions `0x0203`, `0x020B` and `0x0211`). Client-only actions are `0x012F`, `0x0130`, `0x0132`, `0x0133`, `0x0136`, `0x013A`, `0x013B`, `0x013F`, `0x0141` and `0x0143`. Outlook leaves the client-only elements out of the server rule. A rule that needs the client then gets its whole action list replaced by a single deferred action: its server actions are dropped, and Outlook runs the rule itself when the deferred action arrives.
* **Outlook 2002** keeps the server actions alongside the deferred action. The rule starts with an `OP_DEFER_ACTION` action whose data is the one byte `"1"`, and the whole rule is embedded in its provider data ([§2](#2-uploading-rules)). When the rule fires, Exchange delivers a *deferred action message* (class `IPC.Microsoft Exchange 4.0.Deferred Action`). Outlook matches it to the rule by `PR_RULE_PROVIDER` and runs the client-only parts from the embedded copy. Failures arrive as `IPC.Microsoft Exchange 4.0.Deferred Error` messages and are listed in "Rules in Error". A rule with "on this computer only" is handled only on the computer whose ID is in its provider name ([Rules §8.16](Rules.md#816-profilestampparameter)).
* **Outlook 2003** matches deferred action messages to rules as Outlook 2002 does. A message whose provider is `MSFT:TDX OOF Rules` or `MSFT:TDX Rules` comes from an Exchange assistant's rule rather than one of Outlook's.
* **Outlook 2010 and 2013** match a deferred action message to its rule by ServerRuleId, for rules from version 1000000 to `0x140000`.

**Running deferred actions.** For a rule that the server matched and handed back, Outlook 2003 runs a shorter version of the run ([Running §2](Running.md#2-processing-the-rules)). It skips the rule if it is disabled or can't be run, and retests only the conditions and exceptions that are client-only, apart from "on this computer only". If there are none, it runs the actions without testing anything, because the server has already matched the rest. Outlook 2007–2013 also retest the RSS conditions `0x00F5` and `0x00F7` and their exceptions `0x0219` and `0x021B`.

**Cleaning up** (Outlook 2007–2013). In Cached Exchange Mode, a routine named `HrCleanupDAM` opens the message that a deferred action message refers to (`PR_DAM_ORIGINAL_ENTRYID`). If the message can't be found, it deletes the deferred action message. Otherwise it reads the message's property `0x0E2E0003`. When bit `0x1` of that property is clear, it runs the deferred actions with run mode `4` ([Running §1](Running.md#1-when-rules-run)). When bit `0x1` is set, it skips the message, which its debug message calls a "stale hidden message".

## 5. Reading server rules back

When Outlook reads the server's rules, it turns them back into its own rules:

* **Outlook 98** maps `PR_RULE_STATE`'s `ST_ENABLED` (`0x1`) and `ST_EXIT_LEVEL` (`0x10`) to Enabled and a "stop processing more rules" action, and restores the rule's Flags from offset `0x18` of the provider data.
* **Outlook 2000** builds local rules from the rows of the server's rules table in one of two ways. One copies Flags from offset `0x18` of the provider data, turns the rule on when `PR_RULE_STATE` has `ST_ENABLED`, sets ServerRule, and adds "stop processing more rules" for `ST_EXIT_LEVEL`. The other puts the provider data into a memory stream and builds a new rule object from it before setting ServerRule. What that stream holds was not traced.
* **Outlook 2002** reads a rule it created from the copy embedded in its provider data, Flags included. Any other server rule, such as an Inbox Assistant rule, is rebuilt from its restriction and actions, named from `PR_RULE_NAME` (or a generated name), and enabled if its `ST_ENABLED` bit is set:
  * `OP_MOVE` and `OP_COPY` become move or copy to folder, or "delete it" when the target is Deleted Items;
  * `OP_REPLY` becomes "have server reply using";
  * `OP_FORWARD` becomes forward, redirect or forward as attachment, depending on its flags;
  * `OP_TAG` on `PR_IMPORTANCE` or `PR_SENSITIVITY` becomes "mark it as"; a flag tag becomes "flag message";
  * `OP_DELETE` becomes "delete it";
  * the Inbox Assistant's `OP_DEFER_ACTION`, whose data starts with `n`, becomes an alert or sound action;
  * `ST_ENABLED` becomes Enabled, and `ST_EXIT_LEVEL` adds "stop processing more rules";
  * `OP_OOF_REPLY`, `OP_BOUNCE` and `OP_DELEGATE` have no element.
* **Outlook 2003** rebuilds the conditions of a foreign rule by the property each restriction tests. A restriction inside `RES_NOT` becomes the matching exception (the condition's ID + `0x012C`). Outlook 98's reader recognises the same properties, except `PR_NEWSGROUP_NAME`.

  | Property | Element |
  |---|---|
  | `PR_MESSAGE_TO_ME` | `0x00C8` my name is in the To box when true, `0x00CA` when false |
  | `PR_MESSAGE_CC_ME` | `0x00E2` my name is in the Cc box |
  | `PR_MESSAGE_RECIP_ME` | `0x00E3` my name is in the To or Cc box |
  | `PR_IMPORTANCE` | `0x00D2` |
  | `PR_SENSITIVITY` | `0x00D3` |
  | `PR_MESSAGE_CLASS` | `0x00E4` uses the form, looked up by message class |
  | `PR_SUBJECT`, `PR_NORMALIZED_SUBJECT` | `0x00CD` words in the subject |
  | `PR_BODY` | `0x00CE` words in the body |
  | `PR_TRANSPORT_MESSAGE_HEADERS` | `0x00E8` words in the message header |
  | `PR_SENDER_SEARCH_KEY` | `0x00CB` from, or `0x00E6` words in the sender's address, depending on the test |
  | `PR_SEARCH_KEY` in a recipient subrestriction | `0x00CC` sent to |
  | `PR_MESSAGE_DELIVERY_TIME` | `0x00E1` received in a date span |
  | `PR_MESSAGE_SIZE` | `0x00E0` size |
  | `PR_FLAG_STATUS`, flag request named properties `0x8530`/`0x8531` | `0x00D0` flagged for action |
  | `PR_NEWSGROUP_NAME` (`0x0E24`) | `0x00D7` assigned to category, with the property's value as the category |
  | `PR_MESSAGE_FLAGS` & `MSGFLAG_HASATTACH` | `0x00DE` has an attachment; a test that the flag is clear becomes the opposite (`0x020A` as a condition) |

  `PR_SENDER_NAME`, `PR_DISPLAY_NAME` and `PR_RECIPIENT_TYPE` restrictions are skipped. Other `PR_MESSAGE_FLAGS` tests ask for `0x00DD`, which isn't in the definition tables. Any other property fails with `MAPI_E_NO_SUPPORT` (`0x80040102`). Outlook 2003 reads no `0x00F1` or `0x00F3` back, and nothing produces `0x00E5` or `0x00CF` here.
* **Outlook 2010 and 2013** still turn an `OP_TAG` on `PR_SENSITIVITY` into `0x0138`, and the Keywords tag into `0x0152`, raising the rule to 1200000. An `OP_TAG` on `PR_POLICY_TAG` now becomes `0x0153`, with the rule raised to `0x140000`. In one case they also take Flags from offset `0x18` of the provider data ([Rules §5.2](Rules.md#52-rule-flags)). When they read the server's rules, they remove every server rule whose `PR_RULE_NAME` starts with `#NET`, the server copies of the old Net Folders rule. The same pass resets the ServerRuleId counter ([Rules §5.1](Rules.md#51-ruleheader)) and finds the newest provider-data timestamp ([§6](#6-client-and-server-rules-conflict)).

## 6. Client and server rules conflict

From Outlook 98, Outlook compares the rules it has with the rules on the server, using the footer's Timestamp ([Rules §6](Rules.md#6-rulesfooter)) and the newest timestamp in the server rules' provider data.

* **Outlook 98** checks when it reads the server's rules, noting whether any local rule could go to the server. If neither side has rules, nothing happens. If both do and the stored footer Timestamp equals the server's newest, nothing happens either. Otherwise it shows a dialog: "Rules created in this profile conflict with rules on the Microsoft Exchange Server. Only one set of rules can be saved. Which rules do you want to save?" with Client, Server and Cancel.
  * **Client** keeps the local rules to be uploaded.
  * **Server** takes the server's timestamp and deletes the local rules that would go to the server.
  * If the chosen side has no rules, Outlook first asks "There are no rules in your current selection. Do you wish to proceed?" and shows the dialog again on No.
  * The message "Your client rules have been modified more recently than your Exchange Server rules" is still in the resources and still unused, as in Outlook 97.
* **Outlook 2000** makes the same check, with the same dialog.
* **Outlook 2002** asks: "The rules on this machine do not match the rules on your Exchange server. Only one set of rules can be kept. You will usually want to keep the rules on the server. Which rules do you want to keep?" (Client / Server).
* **Outlook 2003 and 2007** keep that prompt. Outlook counts the local rules that can go to the server and compares the footer Timestamp with the newest server timestamp. Any difference counts, whichever side is newer. If neither side has anything, nothing happens. If the two differ, Outlook shows the prompt, but only on its main thread; elsewhere it gives up. The prompt's buttons are Client (keep the local rules and this timestamp), Server (take the server's rules and timestamp) and Cancel (give up). The comparison takes flags from its caller. One skips the check, one marks a call from saving, and one makes Outlook prompt when only the local side has rules. No caller sets that last flag, so in practice the prompt appears only when the server has rules and its newest timestamp differs from the footer's. Outlook 2007 rewords the prompt: "The rules on this computer do not match the rules on Microsoft Exchange. …".
* **Outlook 2010 and 2013** keep the reworded prompt and the same logic. A further flag, also tested by Outlook 2007, makes the comparison give up instead of asking. If the first load of the rules fails, they load them again with the flag that skips the comparison cleared. Outlook 2013 also skips the comparison in a store without Exchange server rules, such as a PST.

**The footer Timestamp** ([Rules §6](Rules.md#6-rulesfooter)) over time:

* **Outlook 97**: when the Rules Wizard window saves, it supplies this timestamp; other saves write the stored value again. `RULESWIZ.DLL` has the message "Your client rules have been modified more recently than your Exchange Server rules", but no code uses it, so Outlook 97 never compares this timestamp.
* **Outlook 98** is the first version to compare it with the server's rules, and asks the user which set to keep when they disagree ([§6](#6-client-and-server-rules-conflict)).
* **Outlook 2002** keeps it in memory as minutes since 1601-01-01 (OLE days × 1440 + 157255200). It uses `0x5AE980E0` for "none", and writes that value as a null OleDateTime. Each upload to the server sets the provider-data timestamp to the current local time and then stores that same value here ([§2](#2-uploading-rules)).
* **Outlook 2003–2013** keep the "none" value `0x5AE980E0`, and compare as Outlook 2002 does.

## 7. Inbox Assistant and Out of Office rules

**The header's Inbox Assistant settings** ([Rules §4.5](Rules.md#45-inbox-assistant-settings)):

* **PromptToConvertInboxAssistantRules** is Outlook 97's option "Prompt to convert Inbox Assistant rules": `1` = ask whether to convert the Inbox Assistant rules found on the server. "Do not prompt me again" clears it. Outlook 98 has the same option and prompt. Outlook 2000's Options dialog no longer has the option, but the prompt is unchanged, so "Do not prompt me again" still clears it.
* **ConvertInboxAssistantRules** is the last answer to that prompt: `1` = Yes (convert), `0` = No. Outlook 98 and 2000 still show the prompt, with Yes, No, "Do not prompt me again" and "I want to use the Inbox Assistant instead".

**Converting Inbox Assistant rules** (Outlook 98). When Outlook 98 finds active Inbox Assistant rules on the server, and the option in [Rules §4.5](Rules.md#45-inbox-assistant-settings) is on, it asks: "Rules Wizard has detected active Inbox Assistant rules located on the Microsoft Exchange Server. Would you like to convert these to Rules Wizard rules?" with Yes, No, "Do not prompt me again" and "I want to use the Inbox Assistant instead". Converted rules are deleted from the server. Rules that can't be converted are reported one by one, with a reason:

| Reason | Cause |
|---|---|
| Too complex | A recipient subrestriction on a property other than `PR_SENDER_NAME` or `PR_DISPLAY_NAME`. |
| Type not supported | A restriction with more than one negated (`RES_NOT`) part. |
| Form conditions | A test of `PR_MESSAGE_CLASS`, which is how forms are expressed. |
| Reply template | A server reply whose template can't be imported. |
| A limitation of the import | Anything else. |

`RES_COMPAREPROPS`, `RES_SIZE` and `RES_EXIST` restrictions are skipped. Actions are converted by MAPI action type: `OP_MOVE` and `OP_COPY` to move or copy, `OP_REPLY` to a reply, `OP_DEFER_ACTION` to an alert or sound, `OP_FORWARD` to forward, `OP_TAG` to a tag action, and `OP_DELETE` to "delete it" (`0x012D`). `OP_OOF_REPLY`, `OP_BOUNCE` and any unknown type become `0x013D`, an action no definition table has, so Outlook 98 can't run them ([Rules §7.6](Rules.md#76-identifiers-outside-the-tables)). `OP_DELEGATE` adds no element.

**Out of Office rules** are server rules whose `PR_RULE_PROVIDER` is `MSFT:TDX OOF Rules`. They are created by Exchange's Out of Office Assistant, not by the code that reads and writes this format, and are never stored in it:

* **Outlook 2003** has no Out of Office Assistant: neither `OUTLLIB.DLL` nor its resources have its dialogs. Outlook only recognises the provider name on deferred action messages ([§4](#4-client-only-parts-and-deferred-actions)), and through the Exchange store provider's cached-mode query ([Storage §1](Storage.md#1-the-rules-message)).
* **Outlook 2007**'s "Out of Office Assistant" dialog is Exchange 2007's: on or off, a time range, and the reply text. It has no rule editor. Its only use of the provider name is the same deferred-action test.
* **Outlook 2010**'s Out of Office dialog is "Automatic Replies", which has a "Rules..." button. `OUTLOOK.EXE` has no rule editor for it. The Exchange assistants' dialogs are in `MAPIR.DLL`, the resources of Office 2010's MAPI: an older "Automatic Replies" dialog with a rule list, "Inbox Assistant" and two "Edit Rule" dialogs. Their conditions are From, Sent To, Sent directly to me, Copied (Cc) to me, Subject and Message body. Their actions include Alert, Delete, Move, Copy, Forward, Reply with template and Return to Sender. The provider names `MSFT:TDX OOF Rules` and `MSFT:TDX Rules` are in `OLMAPI32.DLL`. **[Inferred]** The "Rules..." button opens that editor, which keeps its rules on the server under those providers rather than in this format. `OUTLOOK.EXE` still uses the provider names only in the deferred-action test.
* **Outlook 2013** is the same as Outlook 2010: the same "Automatic Replies" dialog, the same four Exchange assistant dialogs in `MAPIR.DLL`, and the provider names used only in the deferred-action test.

No code in Outlook 2003 or 2007 creates an element with ID `0x014D` or `0x014E`, or a rule with rule-set mask `1`, and Outlook 2010 and 2013 no longer define those elements or the mask ([Rules Wizard §1](RulesWizard.md#1-element-definitions)). So the guess that mask bit `0x1` marks Out of Office or other server-only rules is not supported by anything in Outlook 2003 or 2007. If those elements were meant for Out of Office rules, the code that would use them was never shipped in these versions.

## 8. Rules Outlook can't show

On an Exchange server of version 14 or later, Outlook 2010's rules window asks the server's `ExchangeMailboxRules14` interface whether the mailbox has rules Outlook can't show. If so, it shows "There are rules created with a different version of Outlook or Outlook Web Access that are not shown". **[Inferred]** These are rules created by Outlook Web Access or Exchange 2010 that this format can't express. Outlook 2013 asks the same interface; there is no `ExchangeMailboxRules15`.
