# The Rules Wizard

This document describes the editor Outlook uses for rules: the Rules Wizard, renamed Rules and Alerts in Outlook 2003. It covers which elements the wizard offers, how it fills in some parameters, and how its dialogs changed between versions. It is a companion to the [file format specification](Rules.md).

As in the format specification, a statement about an Outlook version was read from that version's code, and the addresses are in [Decompilation notes](Decompilation.md).

## Contents

* [1. Element definitions](#1-element-definitions)
* [2. Filling in parameters](#2-filling-in-parameters)
* [3. Dialogs by version](#3-dialogs-by-version)

## 1. Element definitions

Outlook keeps a *definition* for each element. Definitions aren't written to the file, but they decide which elements the Rules Wizard offers, which rules can run on the server, and which elements a version keeps when it loads a file. A definition holds:

* the element's group: condition, action, exception, item type (`0x0064`) or event (`0x0190`);
* its parameter class (the *kind*), which decides the layout in [Rules §8](Rules.md#8-parameters). The kind numbers changed between versions, but the kind isn't written to the file, so that doesn't change the format;
* an **item-type mask** and an **event mask** (below);
* a **client-only** flag, which matches the client-only column of `docs/Rules Sever Side.xlsx` for every Outlook 97 element ([Server rules §1](ServerRules.md#1-which-rules-run-on-the-server));
* the string ID of its UI text, for example "with %s in the subject". Two more strings come from it: text + 1000 is the placeholder shown underlined until a value is chosen ("specific words"), and text + 2000 is the prompt in the edit dialog ("Specify a word or phrase to search for in the subject:"). For `0x0064` ("for each *message*") the placeholder is "message" and the prompt is "Select a message type:".

**The masks.** The wizard offers an element, and a rule is consistent, only if both of the element's masks overlap the rule's. The rule's masks are built from its `0x0064` ("for each *message*") item types ([Rules §8.2](Rules.md#82-itemtypeparameter)) and its `0x0190` ("apply this rule *after the message arrives*") events ([Rules §8.1](Rules.md#81-eventparameter)): `0x1` = arrives, `0x4` = sent. For example, "notify me when it is read" and "Cc the message to" have events `4`, so they're only offered for rules on sent messages. Outlook 97 never sets bit `0x2` of either rule mask. In the item-type mask it would be an item type Outlook 97 never defines. In the event mask, the rule's events are copied as `0x1` → `0x1` and `0x4` → `0x4`, and the third event, "after the server receives the message" (`0x8`), is never mapped. **[Inferred]** Bit `0x2` was meant for that third event. Outlook 2010 clears event bit `0x2` in every definition, and Outlook 98–2002 reserve item-type bits `0x2` and `0x4` that no item type uses ([Rules §8.2](Rules.md#82-itemtypeparameter)).

**Which elements the wizard offers.** Later versions add tests that hide or refuse elements:

* **Hidden elements.** In Outlook 2010 and 2013, the wizard leaves out an element it may not offer, unless the rule already contains it. An element may not be offered when a flag of its definition is clear (only Alert E-mail, `0x00F3`, which only alerts create), and the InfoPath elements (`0x00F4`, `0x0218`) when InfoPath isn't available. Outlook 2013 also hides "perform a custom action" (`0x013F`).
* **Refused elements.** Outlook 2010 RTM won't let the wizard use the relevance elements (`0x00ED`, `0x0145`). Its later updates also refuse the custom action, "start application" and "run a script" unless unsafe actions are allowed ([Running §6](Running.md#6-unsafe-actions)). Outlook 2013 refuses only the custom action.
* **Server-only actions.** Outlook 2002 added a field to its definitions that is set only for redirect (`0x0144`) and server reply (`0x0146`). Outlook 2002 and 2003 never use it. Outlook 2010 and 2013 hide these two actions when the store has no Exchange server rules, such as a PST. **[Inferred]** The field therefore marks the actions that only the Exchange server can carry out.
* **Availability.** Outlook 2010 and 2013 offer the retention policy action (`0x0153`) only when retention policies are available. Outlook 2013 also checks "mark it as *importance*" (`0x0137`, [Rules §8.6](Rules.md#86-importanceparameter)).

**The rule-set mask (Outlook 2003 and 2007).** Each of Outlook 2003's element definitions has a mask of the kinds of rule set the element belongs to, and Outlook's own rules always use kind `2`. The mask isn't written to the file, but it decides which elements survive loading:

* After reading an element whose mask lacks bit `0x2`, Outlook discards it and doesn't add it to the rule. Only the hidden actions `0x014D` ("have server reply using *a specific message*") and `0x014E` ("notify me using a .NET notification") have such a mask (`1`). Nothing in Outlook 2003 creates either of them: they appear only in the definition table, so Outlook 2003 can neither make nor keep them.
* The mask also decides one more thing. The Rules Wizard offers only elements whose mask overlaps the rule's. In a rule set without bit `0x1`, Outlook treats `0x0136` (play a sound), `0x0149` (start application), `0x014B` (run a script), `0x00EE`/`0x0214` (account), `0x00F0`/`0x0215` (address book), and moving or copying to some folders, as tied to this computer, and links them to the condition "on this computer only" (`0x00EF`).

**[Inferred]** Bit `0x1` marks rules that run on the server: no element there depends on the computer, and `0x014D` ("have server reply using *a specific message*") is the only element whose event mask is `0x2`, the event bit that is **[Inferred]** meant for "after the server receives the message". Nothing in Outlook 2003 or 2007 supports this guess, though, and the Out of Office rules don't explain it ([Server rules §7](ServerRules.md#7-inbox-assistant-and-out-of-office-rules), [Rules Appendix A](Rules.md#appendix-a-open-questions)). Outlook 2007 still drops these elements.

Outlook 2010 removes the rule-set mask. Its definitions still have the field, but it is `0` in every one and is no longer used: no element is dropped when loading, and the two elements with mask `1`, `0x014D` ("have server reply using *a specific message*") and `0x014E` ("notify me using a .NET notification"), are gone. So the whole mechanism, and with it any use of bit `0x1`, is gone. Outlook 2013 is the same.

**Mark it as importance.** Outlook 2013 offers the action only when the store doesn't support the interface `{1291AD20-0F92-4833-BF72-A0F763DDB434}`. The interface is undocumented. **[Inferred]** Only Exchange ActiveSync stores support it, such as an Outlook.com account added in Outlook 2013, so Outlook 2013 doesn't offer "mark it as importance" for them. The evidence is in [Decompilation §10.2](Decompilation.md#102-definitions-and-parameters).

## 2. Filling in parameters

**Document properties** ([Rules §8.9.1](Rules.md#891-matchifmissing)). How the Document or Form Properties dialog sets MatchIfMissing:

* **Outlook 2000** never sets it either. Its Document Properties dialog keeps a non-zero value when it saves the list again, and adds a copy of that property with the tag of the property's other name (for example `Subject` and `Document Subject`) and MatchIfMissing `0`.
* **Outlook 2003–2013** do set it. When the user picks one of the Office document properties from the dialog's menu ([Rules §8.9.2](Rules.md#892-office-document-properties)), the new property gets MatchIfMissing `1`. Saving the list adds a copy under the property's other name with MatchIfMissing `0`. Fields of a form get `0`. Outlook 2007–2013 also record the property's place in the table. In Outlook 2010 and 2013, names the user types in get `0`, and the dialog gets IDs for all 52 names (26 properties under both names) with `GetIDsFromNames` and `MAPI_CREATE`.

**Scripts** ([Rules §8.26](Rules.md#826-scriptparameter)). The "select script" dialog lists the procedures from a list Outlook reads from its VBA project. Each entry has two strings of up to 255 characters, and choosing one copies the first into Name and the second into Function. The current choice is found by comparing Name. With no procedures, both strings are cleared. (Outlook 2003.)

## 3. Dialogs by version

How the user interface changed, version by version. Dialog numbers are resource IDs, which stay the same across versions.

**Outlook 97.** The Rules Wizard add-in. Its Options dialog has "Update server" (Manually, Automatically, Update Now) and "Prompt to convert Inbox Assistant rules" ([Rules §4](Rules.md#4-rulesheader)). It can export rules (G0), and its resources include a "Rules Wizard rule set (\*.rst)" file type.

**Outlook 98.** The Options dialog (2322) has Outlook 97's "Update server" section, Export Rules and Import Rules, and "Prompt to convert Inbox Assistant rules". The Inbox Assistant conversion is dialog 2323 ([Server rules §7](ServerRules.md#7-inbox-assistant-and-out-of-office-rules)), and the client/server conflict dialog is 234 ([Server rules §6](ServerRules.md#6-client-and-server-rules-conflict)).

**Outlook 2000.** The UI strings and dialogs move into a separate resource DLL, `OUTLLIBR.DLL`, with the same IDs. The Options dialog (2322) no longer has the Inbox Assistant option, but the prompt (2323) is unchanged. The Download Options dialog (1129) builds the rule with Flags `0x40` ([Rules §5.2](Rules.md#52-rule-flags)).

**Outlook 2002.**

* Main dialog 2300: "Apply changes to this folder", the ordered rule list with Move Up and Move Down, the rule description with underlined values to edit, and New, Copy, Modify, Rename, Delete, Run Now and Options. Copy (dialog 2999, "Copy rule to...") copies a rule to another folder's rules.
* Wizard pages 2301 (template or blank rule), 2303 (conditions), 2304 (actions), 2305 (exceptions) and 2306 (name, "Run this rule on messages already in the current folder", "Turn on this rule", "Create this rule on all accounts").
* One dialog per parameter, each matching the parameter's fields in [Rules §8](Rules.md#8-parameters): "Search Text" 2331 (a list of words, one parameter per entry), "Flagged Message" 2307, "Flag Message" 2316 (flag and "by" days), "Importance" 2312, "Sensitivity" 2314, "Message Size" 2315 (at least / at most, KB), "Date Received" 2318 (after / before), "Document or Form Properties" 2311 (field, condition, value), "Notification Message" 2313, "Deferred Delivery" 2310 (minutes), "Select Custom Action" 2309 (action and "Action value"), "Relevance" 2332, "Account" 2333, and "Edit Exception List" 23001 for the junk-mail lists.
* "Rules in Error" 2326 lists the client rules that failed while running ([Running §5](Running.md#5-errors)). "Run Rules Now" 2330 runs chosen rules on a folder, optionally with subfolders.
* Options dialog 2322: "Import and export" with Export Rules and Import Rules buttons, and "Rules upgrade" with Upgrade Now ([Rules §9.3](Rules.md#93-upgrading-rules)).
* Download Options dialog 1129 builds the Flags `0x40` rule. Dialog 2215, "Offline rules turned on", offers "Turn off big item rule" and "Move big items back to Inbox".
* Remote mail's "Filter Messages" dialog (1910), "Download only header for items larger than…", doesn't create a rule; only "Download Options" does.
* The conflict dialog is resource 234 ("Rules Wizard", buttons Client / Server).
* Each element's text comes from its definition: text, placeholder and prompt, as in Outlook 97 ([§1](#1-element-definitions)). Outlook 2002's English wording matches [Rules §7](Rules.md#7-elements), with "people or distribution list" for *people or public group*.
* The resources still contain Outlook 97's "Rules Wizard rule set (\*.rst)" file type and its "Your client rules have been modified more recently than your Exchange Server rules" message, but no code that loads them was found.

**Outlook 2003.** Compared with Outlook 2002:

* The Rules Wizard becomes **Rules and Alerts** on the Tools menu. Dialog 2300 is now "E-mail Rules", and a new page 2302, "Manage Alerts", lists Office alerts (2334 "New Alert", with an alert source or web site address; 2335 "Alert Properties", with Alert Source, Alert Description, Modify Alert and View Item). These alerts are what create condition `0x00F3` ("which is an *Alert E-mail*").
* New dialog 2336, "Select Flag Color" ("Flag message using this color"), for `0x0150` ([Rules §8.29](Rules.md#829-flagcolorparameter)).
* Renamed: 2313 "Notification Message" → "Alert Message", for `0x0130` ("display *a specific message* in the New Item Alert window"); 2321 "New Messages of Interest" → "New Item Alerts".
* Removed: 1910 "Filter Messages" and 2323.
* The wizard's templates come in two groups, "Stay Organized" and "Stay Up to Date", plus the blank rules "Check messages when they arrive" and "Check messages after sending". New among them are "Flag messages from someone with a colored flag" and "Send an alert to my mobile device when I get messages from someone". The others include moving messages from someone, with specific words in the subject or sent to a distribution list, deleting a conversation, showing mail in the New Item Alert window, playing a sound, and assigning categories.
* The old junk-mail lists remain as `Junk Senders.txt`, `Adult Content Senders.txt` and `Exception List.txt` strings, next to the new Junk E-mail Filter's options.
* The Options dialog keeps Outlook 2002's "Rules upgrade" section and "Upgrade Now" button.

**Outlook 2007.** Compared with Outlook 2003:

* The main window (2300) adds a "Rule List" and an "Enable rules on all RSS Feeds" checkbox. That is the RSS setting the conditions `0x00F5` ("from RSS feeds with *specified text* in the title") and `0x00F7` ("from any RSS feed") check.
* A new "Flag Message" dialog (2337, "Flag to:" and "For:") edits the follow-up action `0x0151` ("flag message for *follow up at this time*").
* "Document or Form Properties" (2311) gains an "Add to List" button.
* The junk-mail list editors are gone ("Edit Junk Senders" 23000, "Edit Exception List" 23001, and the sender dialog 23002), matching the removal of the old junk-mail conditions.

**Outlook 2010.** Compared with Outlook 2007:

* **Main window (2300):** the RSS checkbox becomes "Enable rules on all messages downloaded from RSS Feeds", and the window gains the note about rules Outlook can't show ([Server rules §8](ServerRules.md#8-rules-outlook-cant-show)).
* **Options (2322):** "We recommend that you upgrade your rules for better performance, unless you also use Outlook 2002 or earlier".
* **Run Rules Now (2330):** adds Select All and Unselect All.
* **New Item Alerts (2321)** becomes "New Mail Alerts".
* **Retention policies:** new dialogs "Retention Policies" (3663) and "Add or Remove Retention Policies" (1361), used outside the Rules Wizard; the rule's parameter text is "retention policy".
* **Wording:** "people or distribution list" becomes "people or public group", the Out of Office condition becomes "which is an automatic reply", and "on this machine only" becomes "on this computer only". The blank-rule templates become "Apply rule on messages I receive" and "Apply rule on messages I send", and the template "Delete a conversation" is gone.
* **Removed:** the junk-mail texts ("from senders on my %s", "suspected to be junk e-mail or from %s", "containing adult content or from %s", "Do not search message for commercial or adult content" and the three list names), and the string table entry "Rules Wizard". The dialogs are still titled "Rules Wizard", and "Select Custom Action" (2309) is still there.
* **Export file types** are no longer in `OUTLLIBR.DLL` ([Rules §9.4](Rules.md#94-exporting-to-older-formats)).

**Outlook 2013.** Compared with Outlook 2010:

* **Removed:** "Select Custom Action" (2309) and the string "a custom action", with the custom action itself ([Rules §7.4](Rules.md#74-actions)). The UI text "perform %s" is still in the string table, and the definition still points to it.
* **Main window (2300), finish page (2306) and Run Rules Now (2330)** each lose one `NativeFontCtl` control; their texts are unchanged.
* **Unchanged:** the client/server prompt (234), 2301–2305, 2307, 2310, New Mail Alerts (2321), Options (2322), Rules in Error (2326), Create Rule (3002), Automatic Replies (3662) and the retention dialogs (3663, 1361). The relevance texts ("with a relevance %s", "add %s to relevance") and "apply retention policy: %s" are still there.
* The Outlook Express import dialogs are gone ([Importing from Outlook Express](Import.md)).
