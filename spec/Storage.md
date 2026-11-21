# Outlook's Copy of the Rules

This document describes where Outlook keeps its own copy of the rules, how it finds and migrates it, and the rules Outlook creates, keeps or deletes by itself. It is a companion to the [file format specification](Rules.md), which defines the stream stored in the rules message.

As in the format specification, a statement about an Outlook version was read from that version's code, and the addresses are in [Decompilation notes](Decompilation.md).

## Contents

* [1. The rules message](#1-the-rules-message)
* [2. Rules Outlook creates itself](#2-rules-outlook-creates-itself)
  * [2.1 By version](#21-by-version)
  * [2.2 The "Clear categories on mail" rule](#22-the-clear-categories-on-mail-rule)
  * [2.3 Outlook 98's junk filter](#23-outlook-98s-junk-filter)

## 1. The rules message

From Outlook 2002 the rules live in a hidden message in each store ([Rules §1.2](Rules.md#12-where-rules-are-stored)). Each store has its own rules, and Outlook saves the rules of every store whose rules have changed.

**Finding it** (Outlook 2003). Outlook opens the Inbox's associated contents table, keeps the rows whose `PR_MESSAGE_CLASS` is `IPM.RuleOrganizer`, sorts them by `PR_LAST_MODIFICATION_TIME`, newest first, and uses the first. So if a store holds several rules messages, the most recently modified wins. It reads the rules from that message's `PR_RW_RULES_STREAM` in its own-copy mode ([Rules §9.2](Rules.md#92-a-rules-own-version)).

**Creating it.** If there is no rules message and Outlook needs one, it creates an associated message with subject `Outlook Rules Organizer` and writes the stream to `PR_RW_RULES_STREAM`.

**Migrating older rules** (Outlook 2003 and 2007; not traced in Outlook 2010 or 2013). When a store has no rules message, and a per-store "already migrated" setting is still clear, Outlook looks for older rules to import:

1. It reads the profile name (`PR_PROFILE_NAME`) from the profile section and opens `%APPDATA%\Microsoft\Outlook\<profile name>.RWZ`, the file Outlook 2000 and earlier keep.
2. If it can't get the profile name, it opens `PR_RW_RULES_STREAM` on the profile section itself instead.

It loads what it found in import mode, which clears every ServerRuleId, and Outlook 2003 raises the stream's stamp to at least 1100000. It then sets the "migrated" setting and marks the rules to be saved into the store's rules message.

**Cached Exchange Mode.**

* **Outlook 2003** exports a function, `HrTriggerCachedExchangeRules`, that Office 2003's Exchange store provider (`EMSMDB32.DLL`) calls to run the client rules on newly arrived items in the default store's Inbox. Outlook runs the job on its main thread. The store provider also gets this computer's 33-character ID from Outlook's `HrGetRulesMachineID`, and uses it to restrict the server's rules table to three providers: Outlook's own rules (`RuleOrganizer`), the Out of Office Assistant's (`MSFT:TDX OOF Rules`) and the Inbox Assistant's (`MSFT:TDX Rules`). For each provider it matches the plain name as a prefix, or the name (`RuleOrganizer2` for Outlook's rules) followed by the computer ID exactly. The rules themselves are stored and read exactly as in online mode.
* **Outlook 2007** no longer exports the trigger, but still exports `HrGetRulesMachineID`. It already handles cached mode as Outlook 2010 does.
* **Outlook 2010 and 2013** export neither function and have no separate trigger for Cached Exchange Mode. Their cached-mode work is in their handling of deferred action messages ([Server rules §4](ServerRules.md#4-client-only-parts-and-deferred-actions)).

## 2. Rules Outlook creates itself

Outlook marks most of the rules it creates with bits of the rule's Flags field ([Rules §5.2](Rules.md#52-rule-flags)).

### 2.1 By version

* **Outlook 98** keeps its junk filter as a hidden rule in memory, not in the file ([§2.3](#23-outlook-98s-junk-filter)).
* **Outlook 2000 and 2002** create the four rules in the table, and find them again by their flags. Outlook 98's and 2000's Net Folders feature adds a hidden rule named `#NET FOLDERS#`, with condition `0x00E7` and action `0x0141`, which Outlook finds again by its name ([Rules §7.3](Rules.md#73-conditions)).
* **Outlook 2003** replaces the junk-mail rules with its Junk E-mail Filter. Every time it saves the rules, it first deletes each rule with Flags `0x08`, `0x10` or `0x20`, and each rule containing condition `0x00E9`, `0x00EB` or `0x00EC`. It keeps the Download Options rule (`0x40`), but at version 1100000 writes it with no element list ([Rules §5.5](Rules.md#55-rules-from-newer-versions)).
* **Outlook 2007** deletes the same junk-mail rules on every save and keeps the Download Options rule, writing its elements at 1200000. It also creates one new rule of its own, which it finds by its elements rather than by a flag ([Rules §4.3](Rules.md#43-clearcategoriesrulecreated)).
* **Outlook 2010** deletes the same junk-mail rules and keeps the Download Options rule. It also deletes any rule named `#NET FOLDERS#` when it saves. Outlook 2007 doesn't.
* **Outlook 2013** does the same as Outlook 2010.

### 2.2 The "Clear categories on mail" rule

Outlook 2007 and 2010 create this rule once, and record that they have done so in the header's ClearCategoriesRuleCreated field ([Rules §4.3](Rules.md#43-clearcategoriesrulecreated)).

**Outlook 2007** uses bit `0x1` to record that it has created its "Clear categories on mail (recommended)" rule. It checks the bit and the registry value `AcceptCategories` after loading the rules:

* If `AcceptCategories` is `0` (the default) and the bit is clear, Outlook adds a rule named "Clear categories on mail (recommended)" with "assigned to any category" (`0x00F6`) and "clear message's categories" (`0x0152`), and VersionStamp 1200000. Outlook then sets the bit. It doesn't add the rule if WriterVersion is below 1000000, if a rule with exactly those elements already exists, or if a store property (`0x66570014`, an 8-byte value) has a top word of `8` or more, which **[Inferred]** marks a server of Exchange 2007 or later.
* If the bit is already set, Outlook only raises an existing rule of that shape to VersionStamp 1200000.
* If `AcceptCategories` is non-zero and the bit is set, Outlook marks the rule deleted and clears the bit.

So a user who deletes the rule doesn't get it back, because the bit stays set. Outlook finds the rule by its elements (`0x0064`, `0x00F6` and `0x0152`), not by its name or Flags.

**Outlook 2010** runs the same code. It creates the same rule, still with VersionStamp 1200000, and sets, keeps or clears the bit in the same cases.

**Outlook 2013** still loads and saves the field, but no longer makes the rule: the registry value `AcceptCategories` and the rule's name are gone from it. Nothing in Outlook 2013 sets the bit, so it only keeps a `1` it finds.

### 2.3 Outlook 98's junk filter

Outlook 98 keeps its junk filter as a hidden rule that it builds in memory rather than saving: one "perform a custom action" element (`0x013F`) whose location is `4.0;<Office path>\outlas.dll;1;00000101001100` and whose name is `AntiSpam`. `OUTLAS.DLL` (an Exchange client extension exporting `ScanMessage` and `HrGetAntiSpamList`) turns its built-in keyword lists into MAPI restrictions: `SUBJECT` tests `PR_NORMALIZED_SUBJECT`, `BODY` `PR_BODY`, `HEADER` `PR_TRANSPORT_MESSAGE_HEADERS` and `FROM` `PR_SENDER_EMAIL_ADDRESS`, grouped with `BEGIN_AND`/`BEGIN_OR` tokens, one list for junk and one for adult content. The file `filters.txt` on the CD describes the same lists in prose. The sender lists are the files `Junk Senders.txt`, `Adult Content Senders.txt` and `Exception List.txt`, edited through `OUTLAS.DLL`'s dialogs.
