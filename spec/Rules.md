# Outlook Rules Wizard (.rwz) File Format

This document specifies the binary format Microsoft Outlook uses to store its rules: the `.rwz` files that Outlook's Export Rules writes, and the copy of the rules Outlook keeps in the mailbox. It is written for anyone who wants to read or write these files, and it records which version of Outlook introduced each part of the format. Microsoft doesn't publish the format. It was worked out from 330 sample files written by Outlook and from Outlook's own code.

**How to read it.** [§1](#1-introduction) introduces rules, shows where Outlook stores them, and decodes a complete example file byte by byte. [§2](#2-common-data-types) defines the small building blocks used throughout, and [§3](#3-format-versions) shows how to tell the versions of the format apart. [§4](#4-rulesheader)–[§8](#8-parameters) then define every structure, in the order they appear in a file. [§9](#9-versions-and-compatibility) explains how versions of Outlook read and write each other's rules, and [§10](#10-reading-and-writing) sums up what readers and writers must do. [§1.4](#14-outlook-versions-at-a-glance) summarises what each version of Outlook changed.

#### Companion documents

This document covers what is needed to read and write rules files. What Outlook does with rules is described separately:

* [Running rules](Running.md): when Outlook runs rules, how each condition is tested and what each action does.
* [Exchange server rules](ServerRules.md): which rules Outlook uploads to the server, what the server copy holds, and how Outlook reads server rules back.
* [Outlook's copy of the rules](Storage.md): the rules message in the mailbox, and the rules Outlook creates and deletes itself.
* [The Rules Wizard](RulesWizard.md): which elements the editor offers, and its dialogs in each version.
* [Importing from Outlook Express](Import.md): how Outlook 2002–2010 turn Outlook Express rules into Outlook rules.
* [Decompilation notes](Decompilation.md): the evidence from Outlook's code, with the address of every function cited.

## Contents

* [1. Introduction](#1-introduction)
  * [1.1 Rules](#11-rules)
  * [1.2 Where rules are stored](#12-where-rules-are-stored)
  * [1.3 The format at a glance](#13-the-format-at-a-glance)
  * [1.4 Outlook versions at a glance](#14-outlook-versions-at-a-glance)
  * [1.5 Conventions](#15-conventions)
* [2. Common data types](#2-common-data-types)
  * [2.1 Count](#21-count)
  * [2.2 String](#22-string)
  * [2.3 Counted entry ID](#23-counted-entry-id)
  * [2.4 OleDateTime](#24-oledatetime)
  * [2.5 Object tag](#25-object-tag)
  * [2.6 GUID](#26-guid)
* [3. Format versions](#3-format-versions)
  * [3.1 Generations](#31-generations)
  * [3.2 Identifying the format](#32-identifying-the-format)
  * [3.3 Version stamps](#33-version-stamps)
  * [3.4 Version-dependent fields](#34-version-dependent-fields)
  * [3.5 Version 0 streams (G0s)](#35-version-0-streams-g0s)
* [4. RulesHeader](#4-rulesheader)
  * [4.1 Fields](#41-fields)
  * [4.2 Unknown1–3](#42-unknown13)
  * [4.3 ClearCategoriesRuleCreated](#43-clearcategoriesrulecreated)
  * [4.4 Server settings](#44-server-settings)
  * [4.5 Inbox Assistant settings](#45-inbox-assistant-settings)
  * [4.6 ExtraData](#46-extradata)
  * [4.7 Values written by each version](#47-values-written-by-each-version)
* [5. Rule](#5-rule)
  * [5.1 RuleHeader](#51-ruleheader)
  * [5.2 Rule flags](#52-rule-flags)
  * [5.3 Element](#53-element)
  * [5.4 Element order](#54-element-order)
  * [5.5 Rules from newer versions](#55-rules-from-newer-versions)
* [6. RulesFooter](#6-rulesfooter)
* [7. Elements](#7-elements)
  * [7.1 Identifiers](#71-identifiers)
  * [7.2 Mandatory](#72-mandatory)
  * [7.3 Conditions](#73-conditions)
  * [7.4 Actions](#74-actions)
  * [7.5 Exceptions](#75-exceptions)
  * [7.6 Identifiers outside the tables](#76-identifiers-outside-the-tables)
  * [7.7 Element definitions](#77-element-definitions)
* [8. Parameters](#8-parameters)
  * [8.1 EventParameter](#81-eventparameter)
  * [8.2 ItemTypeParameter](#82-itemtypeparameter)
  * [8.3 WordParameter](#83-wordparameter)
  * [8.4 AddressParameter](#84-addressparameter)
  * [8.5 FlaggedForActionParameter](#85-flaggedforactionparameter)
  * [8.6 ImportanceParameter](#86-importanceparameter)
  * [8.7 SensitivityParameter](#87-sensitivityparameter)
  * [8.8 CategoryParameter](#88-categoryparameter)
  * [8.9 FormParameter](#89-formparameter)
  * [8.10 SizeParameter](#810-sizeparameter)
  * [8.11 TimeParameter](#811-timeparameter)
  * [8.12 FormTypeParameter](#812-formtypeparameter)
  * [8.13 SendersListParameter](#813-senderslistparameter)
  * [8.14 RelevanceRangeParameter](#814-relevancerangeparameter)
  * [8.15 AccountParameter](#815-accountparameter)
  * [8.16 ProfileStampParameter](#816-profilestampparameter)
  * [8.17 AddressBookParameter](#817-addressbookparameter)
  * [8.18 AlertParameter](#818-alertparameter)
  * [8.19 FolderParameter](#819-folderparameter)
  * [8.20 PathParameter / MessageParameter](#820-pathparameter--messageparameter)
  * [8.21 FlagParameter](#821-flagparameter)
  * [8.22 DeferParameter](#822-deferparameter)
  * [8.23 CustomActionParameter](#823-customactionparameter)
  * [8.24 RelevanceParameter](#824-relevanceparameter)
  * [8.25 ServerReplyParameter](#825-serverreplyparameter)
  * [8.26 ScriptParameter](#826-scriptparameter)
  * [8.27 FlagForFollowUpParameter](#827-flagforfollowupparameter)
  * [8.28 RetentionPolicyParameter](#828-retentionpolicyparameter)
  * [8.29 FlagColorParameter](#829-flagcolorparameter)
* [9. Versions and compatibility](#9-versions-and-compatibility)
  * [9.1 Version words](#91-version-words)
  * [9.2 A rule's own version](#92-a-rules-own-version)
  * [9.3 Upgrading rules](#93-upgrading-rules)
  * [9.4 Exporting to older formats](#94-exporting-to-older-formats)
  * [9.5 How Outlook 2000 chooses the stamp](#95-how-outlook-2000-chooses-the-stamp)
* [10. Reading and writing](#10-reading-and-writing)
  * [10.1 Reading](#101-reading)
  * [10.2 Writing](#102-writing)
* [Appendix A. Open questions](#appendix-a-open-questions)
* [Appendix B. Corrections to earlier notes](#appendix-b-corrections-to-earlier-notes)

## 1. Introduction

### 1.1 Rules

An Outlook [rule](https://support.microsoft.com/en-us/office/manage-email-messages-by-using-rules-c24f5dea-9465-4df4-ad17-a50704d66c59) is a set of conditions, actions and exceptions that Outlook applies to messages as they arrive or are sent. Outlook shows a rule as a sentence:

```
Apply this rule after the message arrives
from Hugh Bellamy
and with 'invoice' in the subject
move it to the Finance folder
except if it is marked as High importance
```

Each line is an **element**: a condition, an action or an exception, identified by a number ([§7](#7-elements)). Most elements have **parameters**, the values the user fills in, such as the people, the words or the folder ([§8](#8-parameters)). A rules file holds any number of rules:

```
Rules file (.rwz)
├── Rule 1
│   ├── Conditions
│   ├── Actions
│   └── Exceptions
├── Rule 2
│   └── …
└── Rule N
```

Rules began in Outlook 97 as the *Rules Wizard* [add-in](https://www.computerhope.com/download/updates.htm) (`RULESWIZ.DLL`), and were [built into Outlook](https://www.slipstick.com/outlook/rules/rules-wizard/) from Outlook 98 onwards. Outlook 2003 renamed the Rules Wizard **Rules and Alerts**. The format has kept the same shape since Outlook 97. Later versions added fields and elements, and Outlook 2002 switched strings to UTF-16.

Rules run in one of two places. When every part of a rule can be expressed as an Exchange server rule, Outlook also uploads it to the server, which then runs it even while Outlook is closed. A rule with an element only Outlook can carry out, such as playing a sound, is **client-only**: it runs only while Outlook is running ([Exchange server rules](ServerRules.md)).

### 1.2 Where rules are stored

Where Outlook stores rules [depends on its version](https://www.itprotoday.com/email-and-calendaring/how-do-you-delete-and-recreate-corrupt-outlook-rules):

* **Outlook 2002 and later** store rules in the mailbox or PST. The rules are the [`PidTagRwRulesStream`](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxprops/f1fbd19a-9b2c-4c16-a07b-2242b2c0dece) (`PR_RW_RULES_STREAM`, `0x68020102`) property of a [message](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxorule/950a82ff-acde-40b3-8f2f-fc46ceb7a182) named `Outlook Rules Organizer`, whose message class is `IPM.RuleOrganizer`. The message is in the [associated contents table](https://learn.microsoft.com/en-us/office/client-developer/outlook/mapi/contents-tables) of the Inbox ([Storage §1](Storage.md#1-the-rules-message)).

  ![Rules Stream](assets/RulesStream.png)

* **Outlook 2000 and earlier** store rules on disk, at `%APPDATA%\Microsoft\Outlook\<ProfileName>.rwz`. Outlook 97's own copy, called its *profile copy* in this document, uses a different layout from the files it exports ([§3.1](#31-generations)). When a store has no rules message yet, Outlook 2003 and 2007 import this file once and save the rules into the store. This wasn't traced in Outlook 2010 or 2013.

Users can also export rules to a `.rwz` file and import them again. When exporting, Outlook 2003 and later offer to write the file in the current format or in a format for Outlook 2002, 2000 or 98 ([§9.4](#94-exporting-to-older-formats)):

![Rules Export](assets/RulesExport.png)

`.rwz` files and the `PidTagRwRulesStream` property hold the same format, which the Exchange server treats as [client-specific and opaque](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxorule/ee0fd52b-1161-49b8-adab-6b8c2e31c3f3). At the same version the two differ only in the rules' version stamps ([§9.2](#92-a-rules-own-version)). This document calls either one a *rules stream*.

### 1.3 The format at a glance

A rules stream is a header, the rules, and a footer:

```
Stream   := RulesHeader  Rule[NumberOfRules]  RulesFooter
Rule     := RuleHeader   Element[NumberOfElements]
Element  := ObjectTag  Identifier  NumberOfParameters  Parameter[NumberOfParameters]
```

* The **RulesHeader** ([§4](#4-rulesheader)) holds the version stamp that identifies the format ([§3](#3-format-versions)), some settings, and the number of rules.
* Each **rule** ([§5](#5-rule)) has a header with its name and state, then its elements.
* Each **element** has an identifier ([§7](#7-elements)) and parameters whose layout depends on the identifier ([§8](#8-parameters)).
* The **RulesFooter** ([§6](#6-rulesfooter)) holds the last template directory used and the time the rules were last synchronized with the Exchange server.

The oldest layout, Outlook 97's exports, has no header or footer: only the rule count and the rules ([§3.1](#31-generations)).

**An example.** The smallest Outlook 2010 stream holds one enabled rule named `RULENAME`, applied "after the message arrives":

```
00 00 14 00                         VersionStamp        0x00140000 (v14)
00 00 14 06                         WriterVersion       index 6, stamp 0x140000
00 00 00 00 ×3                      Unknown1–3
00 00 00 00                         ClearCategoriesRuleCreated
00 00 00 00  00 00 00 00            ServerRulesOutOfDate, ServerUpdateMode
01 00 00 00                         PromptToConvertInboxAssistantRules
01 00 00 00                         ConvertInboxAssistantRules
00 00 00 00                         ExtraDataSize = 0
01 00                               NumberOfRules = 1
  00 00 14 00                       Rule.VersionStamp
  08 52 00 55 00 … 45 00            Name = StringW "RULENAME"
  01 00 00 00                       Enabled
  00 00 00 00 ×4                    RunError, ServerRule, Flags, ServerRuleId
  36 00 00 00                       DataSize = 54
  02 00                             NumberOfElements = 2
  FF FF 00 00 0C 00 "CRuleElement"  new-class tag, schema 0
    90 01 00 00  01 00 00 00        Identifier 0x190, 1 parameter
    00 00 00 00  01 00 00 00          Reserved, Flags = after received
  01 80                             class tag 1
    64 00 00 00  01 00 00 00        Identifier 0x064, 1 parameter
    00 00 00 00  01 00 00 00          Reserved, Value = 1
00 00 00 00                         TemplateDirectoryLength = 0
02 00 00 00  00 00 … 00             Timestamp: null
00 00 00 00                         Unknown
```

**Where the shape comes from.** The format is the output of the serialization in Microsoft's MFC library, [`CArchive`](https://learn.microsoft.com/en-us/cpp/mfc/reference/carchive-class), as Outlook 97 used it. That explains its less obvious parts:

* Rule elements are `CObject`s of class `CRuleElement` (runtime-class schema 0), written with `CArchive::WriteObject`. Each element is therefore preceded by an object tag ([§2.5](#25-object-tag)).
* A rule (`CRule`) writes its name, Enabled, RunError and ServerRule, then its element list, a `CObList`. `CRule` is not written as an object, so it has no tag.
* `CRuleElement::Serialize` writes the element ID and a has-parameter flag ([§5.3](#53-element)), and then calls the parameter object's own `Serialize`.
* Counts use `CArchive::WriteCount` ([§2.1](#21-count)), strings use `CString`'s length encoding ([§2.2](#22-string)), and dates are written with `operator<<(CArchive&, COleDateTime)` ([§2.4](#24-oledatetime)).
* `RULESWIZ.DLL` (Outlook 97) statically links MFC. It contains the class names `CObject`, `CArchive`, `CRule`, `CRuleComponent` and `CRuleElement`.
* Outlook 98 and later no longer use MFC's `CArchive`, but their own archive classes write the same bytes.

Parameter objects all derive from one base class, whose `Serialize` writes a Reserved field ([§8](#8-parameters)). Each element's definition says which parameter class to create, so the class is never written: parameters carry no class tag. Most string parameters (words, categories, paths, messages) share a single "Reserved + CString" class in Outlook 97. Class names such as `CWordParameter` and `CFolderParameter` come from Outlook's binaries (`docs/Rules Sever Side.xlsx`).

### 1.4 Outlook versions at a glance

| Version | Version stamp written | Changes to the format |
|---|---|---|
| Outlook 97 | `970102` for its own copy; exports have none | The first version. Its own copy uses the G1 layout and its exports the bare G0 layout ([§3.1](#31-generations)). One word or phrase per word condition ([§5.3](#53-element)), and rule names carry the wizard template ([§5.1](#51-ruleheader)). |
| Outlook 98 | `970812` | Adds the rule Flags field and the folder's SecondaryStore ([§3.4](#34-version-dependent-fields)), and elements for the message header, junk mail, Net Folders and "stop processing more rules" ([§7.1](#71-identifiers)). Drops the template from rule names, and stores a failed action's HRESULT in RunError ([§5.1](#51-ruleheader)). |
| Outlook 2000 | `970812`, or `980413` once a rule needs it | Writes 980413 only once a rule needs it ([§9.5](#95-how-outlook-2000-chooses-the-stamp)). Several words per word condition ([§5.3](#53-element)). Adds the account, relevance, redirect, server reply, forward as attachment, print, start application and permanently delete elements ([§7.1](#71-identifiers)). Marks the rules it creates itself with Flags ([§5.2](#52-rule-flags)). |
| Outlook 2002 | `1000000` | The G2 layout: UTF-16 strings, a version word and extra data in the header, and a version, server ID and size in each rule ([§3.1](#31-generations)). Keeps rules from newer versions unparsed ([§5.5](#55-rules-from-newer-versions)). Adds "on this computer only", the address book, scripts and "mark it as read" ([§7.1](#71-identifiers)). Adds rules upgrades and three export file types ([§9.3](#93-upgrading-rules), [§9.4](#94-exporting-to-older-formats)). |
| Outlook 2003 | `1100000` | Adds meeting invitations, Alert E-mail, Desktop Alerts and coloured flags ([§7.1](#71-identifiers)). Reads and writes each rule at its own version ([§9.2](#92-a-rules-own-version)). Four export file types, one of which can write a version-0 stream by accident ([§3.5](#35-version-0-streams-g0s)). Writes MatchIfMissing pairs ([§8.9.1](#891-matchifmissing)). |
| Outlook 2007 | `1200000` | Adds InfoPath forms, RSS feeds, "any category", follow-up flags and "clear message's categories" ([§7.1](#71-identifiers)). Sets ClearCategoriesRuleCreated ([§4.3](#43-clearcategoriesrulecreated)). Starts new rules at 1000000 ([§9.2](#92-a-rules-own-version)). |
| Outlook 2010 | `0x140000` (1310720) | Adds the retention policy action and drops two hidden actions ([§7.1](#71-identifiers)). Writes RunError as `0` or `1` ([§5.1](#51-ruleheader)). Caps the default export at `0x140000` ([§9.4](#94-exporting-to-older-formats)). |
| Outlook 2013 | `0x140000` (1310720) | No new stamp. Reads the relevance elements' parameters as plain Strings ([§8.14](#814-relevancerangeparameter)). |
| Outlook 2016 and later | `0x140000` (1310720) | Not disassembled. Still the Outlook 2010 format (Outlook 2019 samples). |

A version stamp is a 24-bit number that identifies the format version. Up to Outlook 2000 it is a build date (`970812` is 12 August 1997), and Outlook 2002–2007 use the major version × 100000 (`1000000` is version 10). Outlook 2010 switched to the major version written as hex digits, so its stamp is `0x140000` for version 14 ([§3.3](#33-version-stamps)).

### 1.5 Conventions

* All integers are **little-endian**.
* `u8`, `u16` and `u32` are unsigned integers of 1, 2 and 4 bytes. `i32` is a signed 32-bit integer and `f64` is an IEEE 754 double.
* Structures are packed. There is no alignment padding anywhere in the stream.
* Field sizes are given in a Size column, in bytes. "Variable" means the size depends on the content.
* **ANSI** text is 8-bit characters in the writer's code page, in practice ASCII or Windows-1252. **UTF-16** means UTF-16 little-endian, with no byte order mark and no terminating NUL unless stated otherwise.
* Element identifiers are written in hex (`0x00CB`). Version stamps up to 1200000 are written in decimal, as Outlook defines them, and later ones in hex (`0x140000`).
* MAY, SHOULD, MUST, SHOULD NOT and MUST NOT are used as in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

**How each statement is known.** Every statement was established in one of these ways:

| Marker | Meaning |
|---|---|
| *(none)* | **Verified.** Checked against every one of the 330 sample files, written by Outlook 97, 98, 2000, 2003, 2007 and 2019. |
| An Outlook version | **Traced.** Read from that version's code. A statement such as "Outlook 2002–2013 discard Unknown1" means that the code of every version studied in that range was checked and behaves the same way. The addresses are in [Decompilation notes](Decompilation.md). |
| **[Inferred]** | Consistent with all samples and code, but the *meaning* comes from interpretation (for example, a match with an MFC or MAPI structure), not observation. |
| **[Unknown]** | The field's layout is known but its meaning is not. Observed values are listed. |

The versions studied are Outlook 97, 98, 2000, 2002, 2003, 2007, 2010 and 2013 ([Decompilation §1.1](Decompilation.md#11-binaries)). Where the text says a version was **not traced**, that version reads and writes the same bytes, but the behaviour described wasn't looked for in its code. Outlook 2016, 2019 and Microsoft 365 weren't disassembled; they still write the Outlook 2010 format, as the Outlook 2019 samples show.

Writers SHOULD reproduce observed values for fields marked [Unknown]. Readers SHOULD accept any value.

---

## 2. Common data types

### 2.1 Count

A count written with MFC's `CArchive::WriteCount`:

| Field | Size | Description |
|---|---|---|
| Count16 | 2 | The count, if it is less than `0xFFFF`. |
| Count32 | 4, optional | Present only if Count16 is `0xFFFF`. The count. |

RulesHeader.NumberOfRules, RuleHeader.NumberOfElements and FormParameter.NumberOfProperties are counts. Outlook 97 writes all three with `WriteCount`. **[Inferred]** Later versions write the same bytes. No sample has a count of 65535 or more, so the 6-byte form has never been observed.

### 2.2 String

A length-prefixed string. The same prefix encodes two kinds of character data:

* **String8**: the characters are ANSI, and the length counts bytes.
* **StringW**: the characters are UTF-16, and the length counts UTF-16 code units, not bytes or grapheme clusters.

| Field | Size | Description |
|---|---|---|
| Length | 1 | Number of characters if less than `0xFF`. |
| Length16 | 2, optional | Present only if Length is `0xFF`. Number of characters if less than `0xFFFF`. |
| Length32 | 4, optional | Present only if Length16 is `0xFFFF`. Number of characters. **[Inferred]** from MFC; never observed. |
| Value | variable | The characters. There is no NUL terminator. |

Writers MUST use the shortest encoding: 1 byte for 0–254, 3 bytes for 255–65534.

MFC writes a `0xFF 0xFFFE` marker before Unicode `CString`s. This format never contains that marker: the format generation alone decides whether a string is ANSI or UTF-16.

In this document, **String** means "String8 in the ANSI generations and StringW in the Unicode generation" ([§3.1](#31-generations)). Outlook 2002–2013 decide this per version: a String is UTF-16 from version 1000000 and ANSI below it. StringW and String8 mean that encoding in every generation.

### 2.3 Counted entry ID

| Field | Size | Description |
|---|---|---|
| Size | 4 | Length of EntryID in bytes. |
| EntryID | Size | A MAPI entry ID ([MS-OXCDATA](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxcdata) §2.2). |

### 2.4 OleDateTime

The serialized form of an MFC `COleDateTime` (12 bytes).

| Field | Size | Description |
|---|---|---|
| Status | 4 | `0` = valid, `1` = invalid, `2` = null. Only `0` and `2` have been observed. |
| Date | 8 | An OLE Automation date (`f64`). |

When Status is null, Date is `0.0`. Dates before 1899-12-30 are negative, and their fractional part still counts the time of day forward from midnight: `-1.25` is 1899-12-29 06:00 ([MS-OAUT](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-oaut)).

### 2.5 Object tag

Every rule element is preceded by an MFC object tag (`u16`):

| Value | Meaning |
|---|---|
| `0xFFFF` | **New class** (`wNewClassTag`). A class descriptor follows: Schema (`u16`, always `0`), NameLength (`u16`, always `12`), Name (NameLength ANSI bytes, always `CRuleElement`). |
| `0x8001` | **Class reference** (`wClassTag \| 1`). The object's class is entry 1 of the archive's class map, which is `CRuleElement`. |

The class descriptor is written once per stream, before the first element of the first rule. Every later element in the stream, including the first element of rules 2…N, uses `0x8001`. A rule with zero elements writes no tag.

MFC can also emit `0x7FFF` (big object tag) and object back-references (`0x0001`–`0x7FFE`). Neither has been observed. Readers MAY treat them as corruption.

How Outlook handles tags:

* **Reading.** Outlook 2000–2013 are looser than MFC. After `0xFFFF` they read Schema, NameLength and the name into a fixed buffer (456 bytes in Outlook 2000, 260 in Outlook 2007) without checking the name, and they treat **any** other tag as a reference to `CRuleElement`.
* **Writing.** Outlook 2000–2013 write the class descriptor once per archive, before the stream's first element, and `0x8001` after that.
* **Empty slots.** When Outlook 2002–2013 write a rule whose element list has an empty slot, they write the null tag `0x0000` with nothing after it. Their own readers would then misread it: Outlook 2010's has no case for that tag. No sample contains one.

### 2.6 GUID

16 bytes, laid out as a Windows `GUID` ([MS-DTYP](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp) §2.3.4).

---

## 3. Format versions

### 3.1 Generations

The format has three layouts, called *generations* in this document: G0, Outlook 97's bare exports; G1, the ANSI layout of Outlook 97 to 2000; and G2, the Unicode layout of Outlook 2002 and later. A fourth, G0s, is a G1 stream at version 0, which Outlook 2003 writes only by accident ([§3.5](#35-version-0-streams-g0s)).

| Generation | First u32 | Written by | Strings |
|---|---|---|---|
| **G0** (Outlook 97 export) | anything not listed below | Outlook 97's Export Rules | ANSI |
| **G1** (ANSI) | `970102`, `970812`, `980413` | Outlook 97's profile copy; Outlook 98; Outlook 2000 (usually as `970812`, [§9.5](#95-how-outlook-2000-chooses-the-stamp)); Outlook 2002 and later exporting "for Outlook 98/2000" | ANSI |
| **G2** (Unicode) | `1000000`, `1100000`, `1200000`, `0x00140000` | Outlook 2002 and later | UTF-16 |
| **G0s** (version stamp 0) | `0x00000000` | Outlook 2003's Export Rules, when the rules were last saved by a newer Outlook ([§3.5](#35-version-0-streams-g0s)) | ANSI |

**G0** has no version stamp. Its first 2 bytes are the rule count ([§2.1](#21-count)), and its next byte is the first rule name's length. Every Outlook 97 sample starts `01 00` (one rule). G0 is Outlook 97's **Export Rules** format: the exporter writes the rule count with `CArchive::WriteCount` and then each rule, with no header or footer. The rules Outlook 97 keeps for itself use the G1 layout with version stamp 970102 ([§3.3](#33-version-stamps)).

Within G1, version stamp 970102 lacks two fields that 970812 has ([§3.4](#34-version-dependent-fields)).

Field presence by generation:

| Structure / field | G0 | G0s | G1 (970102) | G1 (970812+) | G2 |
|---|---|---|---|---|---|
| RulesHeader.VersionStamp | – | ✓ (=0) | ✓ | ✓ | ✓ |
| RulesHeader.WriterVersion | – | – | – | – | ✓ |
| RulesHeader.Unknown1 … ConvertInboxAssistantRules | – | ✓ | ✓ | ✓ | ✓ |
| RulesHeader.ExtraDataSize, ExtraData | – | – | – | – | ✓ |
| RuleHeader.VersionStamp | – | – | – | – | ✓ |
| RuleHeader.Flags | – | – | – | ✓ | ✓ |
| RuleHeader.ServerRuleId, DataSize | – | – | – | – | ✓ |
| Folder parameter's SecondaryStore | – | – | – | ✓ | ✓ |
| DocumentProperty MatchIfMissing | ✓ | – | ✓ | ✓ | ✓ |
| RulesFooter | – | ✓ | ✓ | ✓ | ✓ |

### 3.2 Identifying the format

The first four bytes identify the generation. A G0 stream can only begin with four zero bytes if it has no rules, and then it is only 2 bytes long (`00 00`). Readers MUST therefore treat a stream shorter than 4 bytes as G0.

Readers SHOULD identify the format by **range** rather than by exact stamp, as Outlook does. Later builds of a version may then write slightly different stamps, and Outlook 2010 and 2013 already know `0x150000`. A G0 stream's first four bytes are its rule count, then the first rule name's length and first character (or the Enabled field when the name is empty). They are therefore either below 960706 or at least `0x01000000`, never inside a stamp range:

| First u32 | Format |
|---|---|
| `0` | G0s |
| below 960706, or `0x01000000` and above | G0 |
| 960706 – 970811 | G1, Outlook 97 profile layout (no rule Flags or folder SecondaryStore) |
| 970812 – 980412 | G1, Outlook 98 |
| 980413 – 999999 | G1, Outlook 2000 |
| 1000000 – 1099999 | G2, Outlook 2002 |
| 1100000 – 1199999 | G2, Outlook 2003 |
| 1200000 – `0x13FFFF` | G2, Outlook 2007 |
| `0x140000` – `0xFFFFFF` | G2, Outlook 2010 and later |

Stamps 960706–970811 also cover pre-release builds whose footer or folder fields differ ([§3.4](#34-version-dependent-fields)). No such file has been seen.

How each version of Outlook recognises a stream:

* **Outlook 97** accepts its own copy at versions 960706 to 970102 and rejects any other.
* **Outlook 98** accepts any stamp from 960706 to 970812. It imports an unsigned (G0) file as version 970102.
* **Outlook 2000** refuses stamps of 1000000 or more, and warns about stamps newer than its own, 980413.
* **Outlook 2002** treats a first u32 with any of its top four bits set (`0x10000000` or more) as G0, which it reads as version 970102. Any stamp above 1000000 is read with the Outlook 2002 layout, and rules whose own stamp is newer are kept unparsed ([§5.5](#55-rules-from-newer-versions)).
* **Outlook 2003** does the same with 1100000 in place of 1000000: any stamp above 1100000 is read with the Outlook 2003 layout and kept as 1100000.
* **Outlook 2007** does the same with 1200000.
* **Outlook 2010 and 2013** do the same with `0x140000`: a G0 stream is read as 970102, and any stamp above `0x140000` is read with the Outlook 2010 layout, which is the Outlook 2002 layout. So Outlook 2013 reads a stream stamped `0x150000` with that layout too.

### 3.3 Version stamps

Outlook identifies format versions with 24-bit *version stamps*. Up to Outlook 2000 a stamp is a `YYMMDD` build date. From Outlook 2002 it is the product's major version × 100000. From Outlook 2010 it is the major version written as hex digits (`0x14` = 14).

| Index | Stamp (decimal) | Stamp (hex) | Meaning |
|---|---|---|---|
| — | 960706 | `0x0EA8C2` | The oldest version Outlook 97 accepts ([§3.2](#32-identifying-the-format)). |
| — | 960723 | `0x0EA8D3` | Footer TemplateDirectory added. |
| — | 960820 | `0x0EA934` | Footer Timestamp added. |
| — | 960918 | `0x0EA996` | "Version 960918" appears in `RULESWIZ.DLL`'s About text. Never written to files. |
| — | 960925 | `0x0EA99D` | Footer Unknown added. |
| 0 | 970102 | `0x0ECD76` | **Outlook 97.** The stamp of Outlook 97's own copy of the rules (G1); its exports (G0) have none. Adds DocumentProperty MatchIfMissing ([§3.4](#34-version-dependent-fields)). Never observed in a sample. |
| — | 970718 | `0x0ECFDE` | Folder parameter SecondaryStore added. |
| 1 | 970812 | `0x0ED03C` | **Outlook 98.** Adds the rule Flags field ([§3.4](#34-version-dependent-fields)). |
| 2 | 980413 | `0x0EF5BD` | **Outlook 2000.** Adds no fields: the layout is the same as 970812, but Outlook 2000 reads NumberOfParameters as a count ([§5.3](#53-element)) and defines more elements ([§7](#7-elements)). Outlook 2000 only writes this stamp once the rules need it; otherwise it writes 970812 ([§9.5](#95-how-outlook-2000-chooses-the-stamp)). |
| 3 | 1000000 | `0x0F4240` | **Outlook 2002** (v10). Adds WriterVersion, the header's extra data, and the rule header's VersionStamp, ServerRuleId and DataSize, and switches strings to UTF-16. Outlook 2002 writes at most this stamp, and doesn't move older rules to it by itself ([§9.3](#93-upgrading-rules)). |
| 4 | 1100000 | `0x10C8E0` | **Outlook 2003** (v11). Adds no fields: the layout is the same as 1000000. Outlook 2003 writes at most this stamp. It adds elements that need it ([§9.4](#94-exporting-to-older-formats)) and the rule without an element list ([§5.5](#55-rules-from-newer-versions)). |
| 5 | 1200000 | `0x124F80` | **Outlook 2007** (v12). Adds no fields. Outlook 2007 writes at most this stamp, and adds elements that need it. |
| 6 | 1310720 | `0x140000` | **Outlook 2010** (v14) and later. Adds no fields: the layout is the same as 1000000. Outlook 2010 and 2013 write at most this stamp, and Outlook 2010 adds the element that needs it, `0x0153` ("apply retention policy: *retention policy*"). Outlook 2019 still writes it. |
| 7 | 1376256 | `0x150000` | v15 (Outlook 2013). Never written and never observed in a file. Outlook 2010's and 2013's tables of stamps have it, but Outlook 2013 still writes `0x140000`, and reads this stamp with the Outlook 2002 layout ([§3.2](#32-identifying-the-format), [§5.5](#55-rules-from-newer-versions)). |

**Outlook's table of stamps.** From Outlook 2002 on, Outlook keeps a table of the stamps it knows, and records a stamp's position in that table next to the stamp in its version words ([§9.1](#91-version-words)). The Index column is that position. Indices 0–7 match the order of a table found in a disassembly of a modern 64-bit Outlook build (`docs/Internals/RWZ Decompilation Notes.docx`). The tables differ by version:

| Version | Table |
|---|---|
| Outlook 2002 | Indices 0–5 as above, then 1300000 at index 6 (a v13 that never shipped). |
| Outlook 2003 | The same as Outlook 2002's, ending with a `0` at index 7. |
| Outlook 2007 | `0x140000` at index 6, then `0` at index 7. So Outlook 2007 knew Outlook 2010's stamp before Outlook 2010 existed. |
| Outlook 2010 and 2013 | All eight stamps above, with `0x150000` at index 7, ending with a `0` at index 8. |

### 3.4 Version-dependent fields

Within a generation, a few fields are present only from a given version. Outlook 97 and 98 read and write these fields only when the stream's version is at least the stamp shown, and every later version up to Outlook 2013 applies the same checks. No other field depends on the version. The generations of [§3.1](#31-generations) differ in more ways than this, because Outlook 2002 also changed the string encoding and the rule header.

| Since | Field | Section |
|---|---|---|
| 960723 | Footer TemplateDirectory | [§6](#6-rulesfooter) |
| 960820 | Footer Timestamp | [§6](#6-rulesfooter) |
| 960925 | Footer Unknown | [§6](#6-rulesfooter) |
| 970102 | DocumentProperty MatchIfMissing | [§8.9](#89-formparameter) |
| 970718 | Folder parameter SecondaryStore | [§8.19](#819-folderparameter) |
| 970812 | RuleHeader Flags | [§5.1](#51-ruleheader) |

Unsigned (G0) streams count as version 970102. G0s streams are version 0, so they have none of these fields except the footer, which Outlook 2003 always writes but reads only from 960723 ([§3.5](#35-version-0-streams-g0s)).

### 3.5 Version 0 streams (G0s)

Two samples (`Versions/Outlook2003/*`) start with a version stamp of 0. The layout is G1 with VersionStamp 0 and without the rule's Flags. The missing field follows from the stamp: rule Flags are only read and written from version 970812, and 0 is below that.

Outlook 2003's Export Rules writes this layout by accident. Its default file type, "Rules Wizard rules", uses the stamp at WriterVersion's index in Outlook 2003's table of stamps ([§9.1](#91-version-words)). When WriterVersion holds a stamp that table doesn't have, such as Outlook 2010's `0x140000`, the index is the table's length, 7, and the entry there is the table's terminating `0`. Outlook then writes the whole file at version 0:

* no WriterVersion or ExtraData;
* no rule VersionStamp, Flags, ServerRuleId or DataSize;
* no folder SecondaryStore or DocumentProperty MatchIfMissing ([§3.4](#34-version-dependent-fields));
* ANSI strings;
* and the footer, which its writer always adds.

Neither G0s sample has a folder or a document property to confirm the third point.

The rest of the G0s header fits too. Outlook 2003 writes both server settings as `0`, and keeps ClearCategoriesRuleCreated as it found it: here `1`, which Outlook 2007 had set and Outlook 2010 kept ([§4](#4-rulesheader)). Outlook 2003 imports such a file at version 0, reading the same fields, but stops before the footer, which its loader only reads from version 960723 ([§6](#6-rulesfooter)). Outlook 2010 and 2013 would write the same layout for a WriterVersion whose stamp they don't know ([§9.4](#94-exporting-to-older-formats)).

---

## 4. RulesHeader

### 4.1 Fields

| Field | Size | Generations | Description |
|---|---|---|---|
| VersionStamp | 4 | G0s, G1, G2 | The format's version stamp ([§3.3](#33-version-stamps)), or `0` in G0s. Writers converting between formats SHOULD write the stamp of the target format; readers SHOULD preserve an unrecognised stamp within a known range ([§3.2](#32-identifying-the-format)). |
| WriterVersion | 4 | G2 | A version word for the rules as a whole ([§9.1](#91-version-words)). Bits 0–23: the version stamp the rules have been brought up to, normally the stamp of the newest Outlook that saved them. Bits 24–31: that stamp's index in Outlook's table of stamps. |
| Unknown1 | 4 | not G0 | **[Unknown]** Writers SHOULD write `0`; readers MUST accept any value ([§4.2](#42-unknown13)). |
| Unknown2 | 4 | not G0 | As Unknown1. |
| Unknown3 | 4 | not G0 | As Unknown1. |
| ClearCategoriesRuleCreated | 4 | not G0 | Flags, of which only bit `0x1` is known: Outlook 2007 has created its "Clear categories on mail (recommended)" rule ([§4.3](#43-clearcategoriesrulecreated)). Readers MUST accept any value. |
| ServerRulesOutOfDate | 4 | not G0 | `1` when the copy of the rules on the Exchange server needs updating ([§4.4](#44-server-settings)). |
| ServerUpdateMode | 4 | not G0 | The "Update server" option of the Rules Wizard's Options dialog: `1` = Manually, `2` = Automatically, `0` = not set ([§4.4](#44-server-settings)). |
| PromptToConvertInboxAssistantRules | 4 | not G0 | The "Prompt to convert Inbox Assistant rules" option: `1` = ask whether to convert the old Exchange Inbox Assistant rules found on the server ([§4.5](#45-inbox-assistant-settings)). Always `1` observed. |
| ConvertInboxAssistantRules | 4 | not G0 | The last answer to that prompt: `1` = Yes (convert), `0` = No ([§4.5](#45-inbox-assistant-settings)). Always `1` observed, but `0` is valid. Readers MUST accept both. |
| ExtraDataSize | 4 | G2 | Number of bytes of ExtraData. Always `0` observed. |
| ExtraData | ExtraDataSize | G2 | Readers MUST skip it and SHOULD preserve it ([§4.6](#46-extradata)). |
| NumberOfRules | 2 (or 6) | all | Number of Rule structures that follow, as a Count ([§2.1](#21-count)). |

The header is 38 bytes in G0s and G1, 46 bytes plus ExtraDataSize in G2, and 2 bytes in G0. Outlook 2000–2013 read and write the fields in this order.

### 4.2 Unknown1–3

Always `0` in the samples, but values of `1` have been seen in the copy of the rules stored in the mailbox. No version studied gives them a meaning:

* **Outlook 97, 98 and 2000** load and save Unknown1–3 unchanged. Nothing else reads or writes them, and new profiles start with `0`.
* **Outlook 2002–2013** discard Unknown1 when loading and always write `0`. They still load and save Unknown2 and Unknown3 unchanged.
* **Outlook 2007, 2010 and 2013** use Unknown2 and Unknown3 only in the loader, the saver, the code for new profiles (which leaves them `0`) and the routine that copies the rules. So they only preserve them. **[Inferred]** The search looked for code near the other header fields, so a use in an unrelated routine could still be missed.

What wrote the `1`s in the mailbox is still unknown; a version after Outlook 2013 is the most likely source ([Appendix A](#appendix-a-open-questions)).

### 4.3 ClearCategoriesRuleCreated

This field was called Unknown4 before Outlook 2007 explained it. Outlook 97–2003 only preserve it, and new profiles get `0`.

Outlook 2007 and 2010 set bit `0x1` once they have created their "Clear categories on mail (recommended)" rule, and clear it if the user turns the feature off ([Storage §2.2](Storage.md#22-the-clear-categories-on-mail-rule)). Outlook 2013 no longer makes the rule, so it only keeps a `1` it finds.

Every sample with `1` was written by Outlook 2007 (stamp 1200000), by Outlook 2010 or later over rules that had been through Outlook 2007, or by Outlook 2003 exporting such rules (the G0s samples).

### 4.4 Server settings

* **ServerRulesOutOfDate** is `1` when the copy of the rules on the Exchange server needs updating ([Server rules §2](ServerRules.md#2-uploading-rules)).
* **ServerUpdateMode** records the "Update server" setting of Outlook 97, 98 and 2000: `1` = Manually, `2` = Automatically, `0` = not set.
* **Outlook 2002–2013** discard both fields when loading and write `0` for both. No "Update server" option was found in Outlook 2003's, 2007's, 2010's or 2013's resources.

### 4.5 Inbox Assistant settings

Before Outlook, Exchange users kept server rules with the Exchange client's *Inbox Assistant*. Outlook offers to convert them into its own rules ([Server rules §7](ServerRules.md#7-inbox-assistant-and-out-of-office-rules)).

* **PromptToConvertInboxAssistantRules** is the option "Prompt to convert Inbox Assistant rules" of Outlook 97 and 98: `1` = ask whether to convert the Inbox Assistant rules found on the server.
* **ConvertInboxAssistantRules** is the last answer to that prompt: `1` = Yes (convert), `0` = No.
* **Outlook 2002–2013** only keep both fields: they load, save and copy them unchanged. No such option was found in Outlook 2003's, 2007's, 2010's or 2013's resources.

### 4.6 ExtraData

Outlook 2002–2013 load these bytes and write them back unchanged. Nothing else reads them, and even the routine that copies the header leaves them out. Outlook 2010 and 2013 write nothing of their own there: they write ExtraDataSize `0` when they hold no bytes. **[Inferred]** It is room for later versions to add header data that older ones keep.

### 4.7 Values written by each version

What a new profile starts with:

| Version | VersionStamp | Unknown1–3, ClearCategoriesRuleCreated | ServerRulesOutOfDate, ServerUpdateMode | Inbox Assistant fields |
|---|---|---|---|---|
| Outlook 98 | — | `0` | `0`, `2` (Automatically) | `1`, `1` |
| Outlook 2000 | 970812 | `0` | `0`, `2` (Automatically) | `1`, `1` |
| Outlook 2002 | 1000000 | `0` (Unknown1 always written as `0`) | always written as `0` | `1`, `1` |
| Outlook 2003 | 1100000, WriterVersion `0x0010C8E0` | `0` | always written as `0` | `1`, `1` |
| Outlook 2007 | 1200000 | `0` | always written as `0` | `1`, `1` |
| Outlook 2010 | `0x140000`, WriterVersion `0x06140000` | `0` | always written as `0` | `1`, `1` |
| Outlook 2013 | `0x140000`, WriterVersion `0x06140000` | `0` | always written as `0` | `1`, `1` |

ClearCategoriesRuleCreated, ServerRulesOutOfDate and ServerUpdateMode in the samples depend on the writer, not the target format:

| Writer | (ClearCategoriesRuleCreated, ServerRulesOutOfDate, ServerUpdateMode) |
|---|---|
| Outlook 98 / 2000 | (0, 1, 2) |
| Outlook 2002 | (kept, 0, 0) |
| Outlook 2003 | (kept, 0, 0) |
| Outlook 2007 | (1 once it has made its Clear categories rule, 0, 0) |
| Outlook 2010 and later | (0 or kept `1`, 0, 0). Outlook 2010 sets `1` once it has made the Clear categories rule, as Outlook 2007 does. Outlook 2013 no longer makes the rule, so it only keeps a `1` it finds. |

---

## 5. Rule

```
Rule := RuleHeader  Element[RuleHeader.NumberOfElements]
```

### 5.1 RuleHeader

| Field | Size | Generations | Description |
|---|---|---|---|
| VersionStamp | 4 | G2 | The rule's own version word, laid out like RulesHeader.WriterVersion ([§9.1](#91-version-words)). The rest of the rule is laid out for this version ([§9.2](#92-a-rules-own-version)). Always equal to RulesHeader.VersionStamp in the samples. Readers SHOULD honour it; writers SHOULD write the stream's stamp. |
| Name | variable | all | String (String8 in G0, G0s and G1; StringW in G2). Outlook limits rule names to 255 characters. May hold a template name after a tab (below). |
| Enabled | 4 | all | `1` = enabled, `0` = disabled. Readers SHOULD treat any non-zero value as enabled. New rules default to enabled. |
| RunError | 4 | all | Non-zero after the rule failed while Outlook was running it on the client (below). Always `0` observed. Readers SHOULD treat any non-zero value as an error. |
| ServerRule | 4 | all | `1` once the rule has been saved to the Exchange server's rules table (below). Usually `0`; `1` in 3 rules written by Outlook 2010 or later. |
| Flags | 4 | G1 (970812+), G2 | `0` for rules the user creates. Outlook sets bits on rules it creates itself ([§5.2](#52-rule-flags)). |
| ServerRuleId | 4 | G2 | The ID of the rule's copy on the Exchange server. `0` for rules never saved to the server (below). Observed `0`, `1` and `2`, non-zero exactly when ServerRule is `1`. |
| DataSize | 4 | G2 | Number of bytes from the end of this field to the end of the rule: NumberOfElements, every object tag, and every element. Matched exactly in all 116 G2 rules. `0` means the rule has **no element list** ([§5.5](#55-rules-from-newer-versions)). Readers MUST accept a DataSize of `0`. |
| NumberOfElements | 2 (or 6) | all | Number of elements in this rule, as a Count ([§2.1](#21-count)): Outlook 97 writes the element list, a `CObList`, with `CObList::Serialize`. Absent when DataSize is `0`. |

**Name and template.** Outlook 97 writes `<rule name>` TAB `<template name>`, where the template is the wizard template the rule was made from, for example `Forward within 20 days\tBuild as I go`. Every Outlook 97 sample has the tab, and samples from later versions sometimes do. Outlook 98–2013 split the name at the first tab when loading and save only the part before it, so they drop the template name. (Outlook 98 still keeps it in memory.)

**RunError.** Outlook 98 stores the failing action's HRESULT here, Outlook 2000–2007 store `1`, and Outlook 2010 and later write `0` or `1` whatever they read. A later action that succeeds can set it back to `0`. How each version sets it is in [Running §5](Running.md#5-errors).

**ServerRule.** Outlook sets it to `1` once it has written the rule to the Exchange server's rules table, and back to `0` when that fails or the server rules are rebuilt ([Server rules §2](ServerRules.md#2-uploading-rules)).

**Flags.** Outlook 98–2013 read and write it only for streams of version 970812 or later, which is why Outlook 97's formats don't have it ([§3.4](#34-version-dependent-fields)). Outlook 98 and 2000 copy it to and from offset `0x18` of the rule's server copy (`PR_RULE_PROVIDER_DATA`, [Server rules §2](ServerRules.md#2-uploading-rules)). From Outlook 2002 the provider data embeds the whole rule instead. Outlook 98–2013 clear Flags to `0` when the user edits a rule that has bit `0x1` or `0x2` set, so those bits **[Inferred]** mark errors that editing fixes ([§5.2](#52-rule-flags)).

**ServerRuleId.** A number Outlook 2002 and later give a rule when they first save it to the server. They store it at offset 4 of the server rule's provider data, and use it to match local rules with server rules. Importing a rules file clears it ([Server rules §2](ServerRules.md#2-uploading-rules)).

**VersionStamp and DataSize.** A rule's version decides the layout of the rest of the rule ([§9.2](#92-a-rules-own-version)). DataSize lets a reader skip a rule whose version or elements it doesn't know ([§5.5](#55-rules-from-newer-versions)).

### 5.2 Rule flags

Outlook 2000 and 2002 create some rules themselves and set their Flags: three junk-mail rules from a built-in table, and the Download Options rule. They then look for them by flag, not by name, which is why a renamed rule is still recognised. Copying a rule in the Rules Wizard clears all flags on the copy.

| Bit | Rule | Elements Outlook 2000 creates |
|---|---|---|
| `0x01`, `0x02` | **[Unknown]** | None. No version from Outlook 98 to 2013 sets these bits (below). |
| `0x08` | Junk e-mail rule | Condition `0x00EB` (junk senders), action `0x012C` (move to folder). |
| `0x10` | Adult content rule | Condition `0x00EC` (adult content senders), action `0x012C` ("move it to the *specified* folder"). |
| `0x20` | "Exception List" rule | Condition `0x00E9` (senders on my Exception List), action `0x0143` (don't search for commercial or adult content). |
| `0x40` | The "big item rule" of the "Download Options" dialog ("Don't download messages larger than *n* KB", with exceptions for chosen senders, high importance and a flag, and a "Restore Default Rule" button) | Condition `0x00E0` (size), actions `0x0130` ("display *a specific message* in the New Item Alert window") and `0x012C` ("move it to the *specified* folder"), exceptions `0x01F7` ("except if from *people or public group*"), `0x01FE` ("except if it is marked as *importance*") and `0x01FC` ("except if it is flagged for *action*"). |

The sample `ExceptionList/Outlook2000_ExceptionList_*.rwz` holds the `0x20` rule as Outlook 2000 creates it.

**Bits `0x01` and `0x02`.** No version up to Outlook 2013 sets them. Outlook 98 and 2000 only clear all the flags when the user edits a rule with either bit set, and carry the bits unchanged to and from the server copy of the rule. So another writer sets them, probably a later Outlook or an Exchange client ([Appendix A](#appendix-a-open-questions)). Outlook 2003–2013 tolerate bad rules that have them: if reading the elements of a rule with either bit set fails, Outlook moves back to where the elements began and carries on instead of failing the load. It doesn't then skip DataSize bytes, so this only works when the rule is the last thing in the stream, as when Outlook reads one rule from a server rule's provider data. In a rules stream, the next rule would be read from the wrong place. Outlook 2010 and 2013 can also take Flags from a server rule, in one case of rebuilding a rule from it: they copy `PR_RULE_PROVIDER_DATA` from offset `0x18` on into the Flags value, `cb` − `0x18` bytes into 4 bytes. Offset `0x18` is where Outlook 98 and 2000 keep Flags in a server rule, so bits written there by those versions can come back. Provider data longer than `0x1C` bytes would overrun the 4-byte value.

Which of these rules each version creates, keeps or deletes is described in [Storage §2](Storage.md#2-rules-outlook-creates-itself).

### 5.3 Element

| Field | Size | Description |
|---|---|---|
| ObjectTag | 2 (+ class descriptor) | See [§2.5](#25-object-tag). |
| Identifier | 4 | Element identifier ([§7](#7-elements)). |
| NumberOfParameters | 4 | Number of parameter structures that follow (below). |
| Parameters | variable | NumberOfParameters parameters. Their layout depends on Identifier ([§8](#8-parameters)). |

Parameter counts:

* "Simple" elements, such as "sent only to me" and "delete it", have **0** parameters.
* Most elements have **1** parameter.
* Word-list elements ([§8.3](#83-wordparameter)) have **one parameter per word or phrase**. The condition matches if any of them matches.
* A simple element with a non-zero count is invalid.

**NumberOfParameters over time.** Outlook 97 and 98 write `1` if the element has a parameter object and `0` if not, and read any non-zero value as "has a parameter"; Outlook 98's word parameter holds a single string. From Outlook 2000 on, Outlook **reads the field as a count** and reads that many parameters. Outlook 2000–2013 write the number of parameters, except that at version 970812 exactly they write at most `1` and only the first parameter ([§9.5](#95-how-outlook-2000-chooses-the-stamp)). Files that store several words as several parameters, as Outlook 2007 does even when exporting "for Outlook 98", therefore need Outlook 2000 or later **[Inferred]**.

**Elements Outlook doesn't know.** In Outlook 2000–2013, an identifier that isn't in Outlook's tables makes the whole load fail, except `0x00EA` (older form of junk senders), which is read as `0x00EB` ([§7.6](#76-identifiers-outside-the-tables)). Outlook 2010 and 2013 no longer define `0x014D` ("have server reply using *a specific message*") and `0x014E` ("notify me using a .NET notification"), so a stream containing either fails to load in them. A reader can't skip an unknown element on its own, because its parameter layout is unknown. In G2 it can skip the whole rule using DataSize ([§5.5](#55-rules-from-newer-versions)).

**Elements Outlook drops.** Outlook 2003 and 2007 also drop some elements they know when loading: those whose rule-set mask lacks bit `0x2`, which are only `0x014D` ("have server reply using *a specific message*") and `0x014E` ([Rules Wizard §1](RulesWizard.md#1-element-definitions)). Outlook 2010 and 2013 drop none.

### 5.4 Element order

Every rule observed starts with:

1. `0x0190`: when the rule runs, "Apply this rule *after the message arrives*" ([§8.1](#81-eventparameter)), and
2. `0x0064` ("for each *message*"): which kinds of item it applies to, "for each *message*" ([§8.2](#82-itemtypeparameter)).

These are followed by conditions, then actions, then exceptions, in the order the user added them. Readers SHOULD NOT depend on this order. Writers MUST emit `0x0190` ("apply this rule *after the message arrives*") and `0x0064` ("for each *message*") first. Every version from Outlook 97 to 2013 defines both elements, and every rule it writes starts with them.

### 5.5 Rules from newer versions

In G2, DataSize lets an older version keep rules it can't read:

* **Outlook 2002** parses a rule's elements only when the rule's version is 1000000 or older. For a newer rule it stores the DataSize bytes unparsed and writes them back unchanged.
* **Outlook 2003** does the same for rules newer than 1100000, **Outlook 2007** for rules newer than 1200000, and **Outlook 2010 and 2013** for rules newer than `0x140000`. So Outlook 2013 keeps a rule stamped `0x150000` as bytes.

Outlook doesn't run a rule it keeps unparsed ([Running §2](Running.md#2-processing-the-rules)) and doesn't upload it to the server.

Readers SHOULD do the same: keep a rule whose version is newer than they support, or that contains an element they don't know, as bytes, and write it back unchanged.

**No element list.** When DataSize is `0`, NumberOfElements and the elements are absent and the next rule follows at once:

* **Outlook 2003** writes the Download Options rule (Flags `0x40`, [§5.2](#52-rule-flags)) this way at version 1100000, and skips that rule's element list when reading it at that version.
* **Outlook 2007–2013** do this only at exactly 1100000. At later versions they write the rule's elements.

---

## 6. RulesFooter

| Field | Size | Description |
|---|---|---|
| TemplateDirectoryLength | 4 | Number of characters in TemplateDirectory. Outlook keeps it ≤ 260 (`MAX_PATH`). |
| TemplateDirectory | variable | The directory used most recently in the "reply using template" browse dialog, for example `C:\Users\<user>\AppData\Roaming\Microsoft\Templates`. ANSI bytes in G0s and G1; UTF-16 code units in G2. No length prefix (unlike [§2.2](#22-string)) and no NUL terminator. Often empty. Writers MUST keep it under 260 characters (below). |
| Timestamp | 12 | An OleDateTime ([§2.4](#24-oledatetime)): when the rules were last synchronized with the Exchange server. Null if they never have been (below). |
| Unknown | 4 | MUST be `0` (all 291 footers). Outlook 97–2013 load and save it unchanged, and nothing else reads or writes it (in Outlook 98, other uses weren't looked for). |

The footer is absent in G0. After the footer the stream MUST end: no sample has trailing bytes.

Outlook 97's loader reads each footer field only if the stream's version is new enough: TemplateDirectory from 960723, Timestamp from 960820, and Unknown from 960925 ([§3.4](#34-version-dependent-fields)). Every stream with a version stamp is newer than that, so all three are always present. Outlook 98–2013 apply the same three checks. G0s streams (version 0) are the one case where they matter: Outlook 2003 reads them without the footer, though it writes one ([§3.5](#35-version-0-streams-g0s)).

**TemplateDirectory length.** Outlook 97 reads at most 259 bytes into a 260-byte buffer, so writers MUST keep it under 260 characters. Outlook 2000–2013 read at most 260 characters. If the length is larger, they don't skip the rest, and the following fields are read from the wrong place.

**Timestamp.** Outlook writes the time it last uploaded the rules to the Exchange server, and compares it with the server's rules to notice changes made elsewhere ([Server rules §6](ServerRules.md#6-client-and-server-rules-conflict)). Outlook 2002–2013 keep it in memory as minutes since 1601-01-01 (OLE days × 1440 + 157255200), use `0x5AE980E0` for "none", and write that value as a null OleDateTime. Outlook 97 writes the timestamp but never compares it.

Observed values:

* Status is null in 231 of 291 samples: those rules were never synchronized with an Exchange server.
* A valid timestamp of `-109205.0` is 1601-01-01 00:00, the `FILETIME` epoch. It is a zero `FILETIME` converted to an OLE date, and means "never saved".
* Several Outlook 2000 samples hold `-649728.2264`, about the year 120 AD. This is presumably garbage: an uninitialised value or a conversion bug.

---

## 7. Elements

### 7.1 Identifiers

Identifiers are grouped by range:

| Range | Group |
|---|---|
| `0x0064` ("for each *message*"), `0x0190` ("apply this rule *after the message arrives*") | Mandatory |
| `0x00C8`–`0x012B` (200–299) | Conditions |
| `0x012C`–`0x018F` (300–399) | Actions |
| `0x01F4`–`0x0257` (500–599) | Exceptions |

Which elements each version knows:

| Version | Conditions | Actions | Exceptions |
|---|---|---|---|
| Outlook 97 | `0x00C8`–`0x00E6` | `0x012C`–`0x0140` | `0x01F4`–`0x0212` |
| Outlook 98 | to `0x00EC` ("containing adult content or from *Adult Content Senders*") | to `0x0143` ("do not search message for commercial or adult content") | to `0x0213` ("except if the message header contains *specific words*") |
| Outlook 2000 | to `0x00EE` ("through the *specified* account") | to `0x014A` ("permanently delete it") | adds `0x0214` ("except through the *specified* account") |
| Outlook 2002 | to `0x00F0` ("sender is in *specified* Address Book") | to `0x014C` ("mark it as read") | to `0x0215` ("except if sender is in *specified* Address Book") |
| Outlook 2003 | adds `0x00F1` ("which is a meeting invitation or update"), `0x00F3` ("which is an *Alert E-mail*") | adds `0x014D`–`0x0150` | adds `0x0216` ("except if it is a meeting invitation or update") |
| Outlook 2007 | adds `0x00F4`–`0x00F7` | adds `0x0151` ("flag message for *follow up at this time*"), `0x0152` ("clear message's categories") | adds `0x0218`–`0x021B` |
| Outlook 2010 | no change | adds `0x0153` ("apply retention policy: *retention policy*"); drops `0x014D` ("have server reply using *a specific message*"), `0x014E` ("notify me using a .NET notification") | no change |
| Outlook 2013 | no change, but `0x00ED` ("with a relevance *in a specific range*") is switched off | no change, but `0x0145` ("add *number* to relevance") is switched off | no change |

Outlook 97 also defines `0x0064` ("for each *message*") and `0x0190` ("apply this rule *after the message arrives*"), as does every later version. The definition tables of each version are in [Decompilation notes](Decompilation.md#3-outlook-97-ruleswizdll).

For conditions `0x00C8`–`0x00E6`, the matching exception is the condition's identifier + 300 (`0x012C`). After that the exception numbers are assigned in sequence and the +300 relationship breaks: `0x00E8` ("with *specific words* in the message header") → `0x0213` ("except if the message header contains *specific words*"), `0x00EE` ("through the *specified* account") → `0x0214` ("except through the *specified* account"), `0x00F0` ("sender is in *specified* Address Book") → `0x0215` ("except if sender is in *specified* Address Book"), and so on ([§7.5](#75-exceptions)).

In the tables below, the "UI text" column gives the Rules Wizard's English wording, with the parameter in italics. "Param" refers to [§8](#8-parameters), and "—" means the element has no parameters. "Client" marks elements that make a rule client-only, according to `docs/Rules Sever Side.xlsx` ([Server rules §1](ServerRules.md#1-which-rules-run-on-the-server)). "Defined in" lists the versions whose element definition tables contain the element; "—" means no table from Outlook 97 to 2013 has it.

### 7.2 Mandatory

| ID | Meaning | Param | Defined in |
|---|---|---|---|
| `0x0064` | "For each *message*": which kinds of item the rule applies to. | [§8.2](#82-itemtypeparameter) | 97–2013 |
| `0x0190` | "Apply this rule *after the message arrives*": when the rule runs. | [§8.1](#81-eventparameter) | 97–2013 |

Every version from Outlook 97 to 2013 defines both, and every rule it writes starts with them ([§5.4](#54-element-order)).

### 7.3 Conditions

| ID | UI text | Param | Client | Notes | Defined in |
|---|---|---|---|---|---|
| `0x00C8` | where my name is in the To box ("sent directly to me" in Outlook 97) | — | | | 97–2013 |
| `0x00C9` | sent only to me | — | | | 97–2013 |
| `0x00CA` | where my name is not in the To box | — | | | 97–2013 |
| `0x00CB` | from *people or public group* | [§8.4](#84-addressparameter) | | | 97–2013 |
| `0x00CC` | sent to *people or public group* | [§8.4](#84-addressparameter) | | | 97–2013 |
| `0x00CD` | with *specific words* in the subject | [§8.3](#83-wordparameter) | | | 97–2013 |
| `0x00CE` | with *specific words* in the body | [§8.3](#83-wordparameter) | | | 97–2013 |
| `0x00CF` | with *specific words* in the subject or body | [§8.3](#83-wordparameter) | | | 97–2013 |
| `0x00D0` | flagged for *action* | [§8.5](#85-flaggedforactionparameter) | | | 97–2013 |
| `0x00D2` | marked as *importance* | [§8.6](#86-importanceparameter) | | | 97–2013 |
| `0x00D3` | marked as *sensitivity* | [§8.7](#87-sensitivityparameter) | | | 97–2013 |
| `0x00D4` | where my name is in the To box and it is a meeting | — | | Never created by the Rules Wizard; supported by Outlook 97's evaluator ([§7.6](#76-identifiers-outside-the-tables)). | — |
| `0x00D5` | where my name is not in the To box and it is a meeting | — | | As `0x00D4`. | — |
| `0x00D7` | assigned to *category* category | [§8.8](#88-categoryparameter) | ✓ | | 97–2013 |
| `0x00DA` | sent to *people or public group* as Cc | [§8.4](#84-addressparameter) | | As `0x00D4` ("where my name is in the To box and it is a meeting"). **[Inferred]** parameter, from the evaluator reading the element's address list. | — |
| `0x00DB` | sent to *people or public group* | [§8.4](#84-addressparameter) | | As `0x00DA` ("sent to *people or public group* as Cc"), but the same test as `0x00CC` ("sent to *people or public group*"). | — |
| `0x00DC` | which is an automatic reply ("which is an Out of Office message" before Outlook 2010) | — | | Matches Exchange's automatic replies, by message class. See the notes below the table. | 97–2013 |
| `0x00DE` | which has an attachment | — | | | 97–2013 |
| `0x00DF` | with *selected properties* of documents or forms | [§8.9](#89-formparameter) | ✓ | | 97–2013 |
| `0x00E0` | with a size *in a specific range* | [§8.10](#810-sizeparameter) | | | 97–2013 |
| `0x00E1` | received *in a specific date span* | [§8.11](#811-timeparameter) | | | 97–2013 |
| `0x00E2` | where my name is in the Cc box | — | | | 97–2013 |
| `0x00E3` | where my name is in the To or Cc box | — | | | 97–2013 |
| `0x00E4` | uses the *form name* form | [§8.12](#812-formtypeparameter) | | Not functional in Outlook 2019. | 97–2013 |
| `0x00E5` | with *specific words* in the recipient's address | [§8.3](#83-wordparameter) | ✓ | | 97–2013 |
| `0x00E6` | with *specific words* in the sender's address | [§8.3](#83-wordparameter) | | | 97–2013 |
| `0x00E7` | *none* (Net Folders) | — | | Hidden. Only in Outlook 98's and 2000's Net Folders rule. See the notes below the table. | 98–2013 |
| `0x00E8` | with *specific words* in the message header | [§8.3](#83-wordparameter) | | | 98–2013 |
| `0x00E9` | from senders on my *Exception List* | [§8.13](#813-senderslistparameter) | ✓ | Junk-mail feature of Outlook 98 and 2000. Never matches. See the notes below the table. | 98–2013 |
| `0x00EA` | *older form of `0x00EB` ("suspected to be junk e-mail or from *Junk Senders*")* | [§8.13](#813-senderslistparameter) | ✓ | Not in Outlook 98's or 2000's tables, but Outlook 2000–2013 read it as `0x00EB`. Probably from pre-release Outlook 98 builds. | — |
| `0x00EB` | suspected to be junk e-mail or from *Junk Senders* | [§8.13](#813-senderslistparameter) | ✓ | Added in Outlook 98, removed in 2003, as `0x00E9` ("from senders on my *Exception List*"). | 98–2013 |
| `0x00EC` | containing adult content or from *Adult Content Senders* | [§8.13](#813-senderslistparameter) | ✓ | Added in Outlook 98, removed in 2003, as `0x00E9` ("from senders on my *Exception List*"). | 98–2013 |
| `0x00ED` | with a relevance *in a specific range* | [§8.14](#814-relevancerangeparameter) | ✓ | Hidden. Switched off in Outlook 2013. See the notes below the table. | 2000–2013 |
| `0x00EE` | through the *specified* account | [§8.15](#815-accountparameter) | ✓ | Offered only for incoming mail until Outlook 2002 allowed it on sent mail too. | 2000–2013 |
| `0x00EF` | on this computer only ("on this machine only" in Outlook 2002–2007) | [§8.16](#816-profilestampparameter) | ✓ | | 2002–2013 |
| `0x00F0` | sender is in *specified* Address Book | [§8.17](#817-addressbookparameter) | ✓ | Requires `0x00EF` ("on this computer only"). | 2002–2013 |
| `0x00F1` | which is a meeting invitation or update | — | | | 2003–2013 |
| `0x00F3` | which is an *Alert E-mail* | [§8.18](#818-alertparameter) | | Created only from an Office alert source ([Rules Wizard §3](RulesWizard.md#3-dialogs-by-version)). | 2003–2013 |
| `0x00F4` | of the *specific* form type (InfoPath) | [§8.12](#812-formtypeparameter) | ✓ | Requires InfoPath. | 2007–2013 |
| `0x00F5` | from RSS feeds with *specified text* in the title | [§8.3](#83-wordparameter) | | Matches the feed's name exactly, ignoring case, not words in the item's title ([Running §3](Running.md#3-condition-tests)). | 2007–2013 |
| `0x00F6` | assigned to any category | — | | | 2007–2013 |
| `0x00F7` | from any RSS feed | — | | Written with no parameter. Readers SHOULD accept zero or one. See the notes below the table. | 2007–2013 |

Notes on the table:

* **`0x00DC` ("which is an automatic reply").** Matches messages whose `PR_MESSAGE_CLASS` is `IPM.Note.Rules.OofTemplate.Microsoft`, ignoring case, on the client and on the server: the class of the Exchange Out of Office template, which Exchange's auto-replies carry (Outlook 2003–2013).
* **`0x00E7`.** Only seen in the hidden `#NET FOLDERS#` rule created by Outlook 98's and 2000's Net Folders (`NetFolders/Outlook2000_NetFolders_Default.rwz`). Outlook 98 defines it with no parameter, the text "(none)" and empty masks, so the wizard never offers it. In Outlook 2000 it means "the subject begins with `#NET FOLDERS#`": Outlook turns it into a prefix test on `PR_SUBJECT`. Net Folders' own messages carry that subject. Outlook 2010 and 2013 no longer match it, and delete the rule when they save ([§5.2](#52-rule-flags)).
* **`0x00E9` ("from senders on my *Exception List*").** Junk-mail feature of Outlook 98 and 2000. Never matches when Outlook 98–2002 run rules ([§8.13](#813-senderslistparameter)). Outlook 2003 removed the feature: it still reads the element, but deletes rules that use it when it saves ([§5.2](#52-rule-flags)), and never matches it, or `0x00EA`–`0x00EC`, when running rules. Outlook 2007–2013 still delete such rules when they save. Outlook 2010 and 2013 still define it, but its UI text is gone (it shows "(none)"), they read its parameter as a plain String ([§8.13](#813-senderslistparameter)), and they never match it.
* **`0x00ED` ("with a relevance *in a specific range*").** Added in Outlook 2000. Hidden unless `HKCU\Software\Microsoft\Office\8.0\Outlook\Relevance` exists. Not traced in Outlook 2002–2007. Outlook 2010 still has a test for it, but won't let the wizard use it ([Rules Wizard §1](RulesWizard.md#1-element-definitions)). Outlook 2013 switches it off: it still defines it, but with no parameter class and empty masks, so the wizard never offers it, its parameter is read as a plain String ([§8.14](#814-relevancerangeparameter)), and the condition always fails.
* **`0x00F7` ("from any RSS feed").** Added in Outlook 2007. Its definition names a parameter class that holds only Reserved, but the wizard creates the element without one, so it is written with NumberOfParameters `0` (as in the sample). Outlook reads a parameter if the count says there is one: readers SHOULD accept zero or one 4-byte Reserved parameter. Its exception `0x021B` ("except if from any RSS feed") is the same.

### 7.4 Actions

| ID | UI text | Param | Client | Notes | Defined in |
|---|---|---|---|---|---|
| `0x012C` | move it to the *specified* folder | [§8.19](#819-folderparameter) | | | 97–2013 |
| `0x012D` | delete it | — | | | 97–2013 |
| `0x012E` | forward it to *people or public group* | [§8.4](#84-addressparameter) | | | 97–2013 |
| `0x012F` | reply using *a specific template* | [§8.20](#820-pathparameter--messageparameter) | ✓ | Path to an `.oft` file. | 97–2013 |
| `0x0130` | display *a specific message* in the New Item Alert window ("notify me using …" in Outlook 97–2002) | [§8.20](#820-pathparameter--messageparameter) | ✓ | | 97–2013 |
| `0x0131` | flag message for *action in a number of days* | [§8.21](#821-flagparameter) | ✓ | The pre-2007 flag. Outlook 2007–2013 offer it only for rules on sent messages; `0x0151` replaces it for received mail. | 97–2013 |
| `0x0132` | clear the Message flag | — | ✓ | | 97–2013 |
| `0x0133` | assign it to the *category* category | [§8.8](#88-categoryparameter) | ✓ | | 97–2013 |
| `0x0136` | play *a sound* | [§8.20](#820-pathparameter--messageparameter) | ✓ | | 97–2013 |
| `0x0137` | mark it as *importance* | [§8.6](#86-importanceparameter) | ✓ | Outlook 2013 doesn't offer it for stores that **[Inferred]** are Exchange ActiveSync accounts ([§8.6](#86-importanceparameter)). | 97–2013 |
| `0x0138` | mark it as *sensitivity* | [§8.7](#87-sensitivityparameter) | ✓ | | 97–2013 |
| `0x0139` | move a copy to the *specified* folder | [§8.19](#819-folderparameter) | | | 97–2013 |
| `0x013A` | notify me when it is read | — | ✓ | Sent-mail rules. | 97–2013 |
| `0x013B` | notify me when it is delivered | — | ✓ | Sent-mail rules. | 97–2013 |
| `0x013C` | Cc the message to *people or public group* | [§8.4](#84-addressparameter) | | Sent-mail rules. | 97–2013 |
| `0x013E` | defer delivery by *a number of* minutes | [§8.22](#822-deferparameter) | ✓ | Sent-mail rules. | 97–2013 |
| `0x013F` | perform *a custom action* | [§8.23](#823-customactionparameter) | ✓ | Runs an action implemented by a DLL. Outlook 2013 no longer runs it. See the notes below the table. | 97–2013 |
| `0x0140` | *none* | — | | Defined by Outlook 97 with no UI text, no parameter and every flag clear: a hidden or retired action. No version runs it. | 97–2013 |
| `0x0141` | *none* (Net Folders) | — | ✓ | Hidden. Only in the Net Folders rule. See the notes below the table. | 98–2013 |
| `0x0142` | stop processing more rules | — | | On the server it is the rule state `ST_EXIT_LEVEL` ([Server rules §3](ServerRules.md#3-server-forms-of-elements)). | 98–2013 |
| `0x0143` | do not search message for commercial or adult content | — | ✓ | Hidden. Does nothing from Outlook 2003. See the notes below the table. | 98–2013 |
| `0x0144` | redirect it to *people or public group* | [§8.4](#84-addressparameter) | | | 2000–2013 |
| `0x0145` | add *number* to relevance | [§8.24](#824-relevanceparameter) | ✓ | Hidden. Switched off in Outlook 2013. See the notes below the table. | 2000–2013 |
| `0x0146` | have server reply using *a specific message* | [§8.25](#825-serverreplyparameter) | | | 2000–2013 |
| `0x0147` | forward it to *people or public group* as an attachment | [§8.4](#84-addressparameter) | | | 2000–2013 |
| `0x0148` | print it | — | ✓ | | 2000–2013 |
| `0x0149` | start *application* | [§8.20](#820-pathparameter--messageparameter) | ✓ | Refused by Outlook 2010's later updates unless unsafe actions are allowed ([Running §6](Running.md#6-unsafe-actions)). Hidden in Outlook 2016 and later. | 2000–2013 |
| `0x014A` | permanently delete it | — | ✓ | Outlook also requires `0x0142` ("stop processing more rules"). | 2000–2013 |
| `0x014B` | run *a script* | [§8.26](#826-scriptparameter) | ✓ | Refused by Outlook 2010's later updates unless unsafe actions are allowed ([Running §6](Running.md#6-unsafe-actions)). Hidden in Outlook 2016 and later. | 2002–2013 |
| `0x014C` | mark it as read | — | ✓ | | 2002–2013 |
| `0x014D` | have server reply using *a specific message* | [§8.20](#820-pathparameter--messageparameter) | | Hidden twin of `0x0146`. Never saved. See the notes below the table. | 2003–2007 |
| `0x014E` | notify me using a .NET notification | — | | Hidden. Never saved. See the notes below the table. | 2003–2007 |
| `0x014F` | display a Desktop Alert | — | ✓ | | 2003–2013 |
| `0x0150` | flag message with *a colored flag* (`RuleElementFlagColorAction`) | [§8.29](#829-flagcolorparameter) | ✓ | Never observed in a file. Outlook 2007–2013 still read and run it but hide it: its event mask is empty, so the wizard no longer offers it. | 2003–2013 |
| `0x0151` | flag message for *follow up at this time* | [§8.27](#827-flagforfollowupparameter) | ✓ | | 2007–2013 |
| `0x0152` | clear message's categories | — | | | 2007–2013 |
| `0x0153` | apply retention policy: *retention policy* | [§8.28](#828-retentionpolicyparameter) | | Needs version `0x140000`. See the notes below the table. | 2010–2013 |

Notes on the table:

* **`0x013F` ("perform *a custom action*").** Runs an action implemented by a DLL. Reported as removed in Outlook 2010, but Outlook 2010 RTM still defines it, still has the "Select Custom Action" dialog, and still runs it. Outlook 2010's later updates refuse it unless an administrator allows unsafe actions ([Running §6](Running.md#6-unsafe-actions)). Outlook 2013 removes it in practice: it still defines it and reads and writes its parameter, but the wizard won't use it, Outlook doesn't run it, and the "Select Custom Action" dialog and the text "a custom action" are gone.
* **`0x0141`.** Only seen in the hidden `#NET FOLDERS#` rule, with `0x00E7`. Defined by Outlook 98 as client-only, with empty masks. In Outlook 2000 it hands the message to Net Folders: Outlook moves it into a folder whose entry ID is kept in property `0x60010102`, schedules Net Folders to process it, and stops processing more rules. Not traced in Outlook 2002. Outlook 2003 and 2007 still stop processing more rules after it. Outlook 2010 and 2013 do nothing for it. They also delete the `#NET FOLDERS#` rule whenever they save ([§5.2](#52-rule-flags)), and remove any server rule whose name starts with `#NET` when they read the server's rules ([Server rules §5](ServerRules.md#5-reading-server-rules-back)).
* **`0x0143` ("do not search message for commercial or adult content").** Added in Outlook 98 with empty masks, so only the junk-mail feature creates it. Removed in 2003. Not traced in Outlook 2000–2002. Outlook 2003 and 2007 still define it but do nothing for it. Outlook 2010 and 2013 still define it, without its UI text, and do nothing for it.
* **`0x0145` ("add *number* to relevance").** Added in Outlook 2000. Hidden; see `0x00ED` ("with a relevance *in a specific range*"). Not traced in Outlook 2002–2010, apart from Outlook 2003's handler and Outlook 2010 RTM, which won't let the wizard use it. Outlook 2013 switches it off as it does `0x00ED`: no parameter class, empty masks, the parameter read as a plain String, and an action that does nothing.
* **`0x014D` ("have server reply using *a specific message*").** A hidden twin of `0x0146` ("have server reply using *a specific message*") with the same text, defined by Outlook 2003 with a Reserved and String parameter, event mask `0x2` and no item types. Outlook 2003 discards it when loading ([Rules Wizard §1](RulesWizard.md#1-element-definitions)), so it never appears in a rule it saves. Outlook 2007 still defines and discards it, and still runs it like "reply using a template". Never observed in a file. Outlook 2010 and 2013 no longer define it, so a stream holding it fails to load, and they have no handler for it.
* **`0x014E` ("notify me using a .NET notification").** Hidden in Outlook 2003 and 2007, with no parameter and empty masks. Discarded when loading, as `0x014D` ("have server reply using *a specific message*"), and has no handler. Never observed in a file. Outlook 2010 and 2013 no longer define it, as `0x014D`.
* **`0x0153` ("apply retention policy: *retention policy*").** Added in Outlook 2010, and the only element that needs version `0x140000` ([§9.4](#94-exporting-to-older-formats)). Offered only when retention policies are available. It sets the message's `PR_POLICY_TAG` and `PR_RETENTION_PERIOD`, on the client and on the server. Outlook 2013 is the same.

### 7.5 Exceptions

Every exception has the same parameter layout as its condition, and is defined in exactly the same versions (Outlook 97–2013). The conditions without an exception are `0x00E7` (Net Folders), `0x00E9` ("from senders on my *Exception List*"), `0x00EB` ("suspected to be junk e-mail or from *Junk Senders*"), `0x00EC` ("containing adult content or from *Adult Content Senders*"), `0x00ED` ("with a relevance *in a specific range*"), `0x00EF` ("on this computer only") and `0x00F3` ("which is an *Alert E-mail*"). Outlook shows an exception as its condition preceded by "except", for example "except if sent directly to me".

| Exception | Wording | Condition |
|---|---|---|
| `0x01F4` | except where my name is in the To box | `0x00C8` |
| `0x01F5` | except if sent only to me | `0x00C9` |
| `0x01F6` | except where my name is not in the To box | `0x00CA` |
| `0x01F7` | except if from *people or public group* | `0x00CB` |
| `0x01F8` | except if sent to *people or public group* | `0x00CC` |
| `0x01F9` | except if the subject contains *specific words* | `0x00CD` |
| `0x01FA` | except if the body contains *specific words* | `0x00CE` |
| `0x01FB` | except if the subject or body contains *specific words* | `0x00CF` |
| `0x01FC` | except if it is flagged for *action* | `0x00D0` |
| `0x01FE` | except if it is marked as *importance* | `0x00D2` |
| `0x01FF` | except if it is marked as *sensitivity* | `0x00D3` |
| `0x0203` | except if it is assigned to *category* category | `0x00D7` |
| `0x0208` | except if it is an automatic reply | `0x00DC` |
| `0x020A` | except if it has an attachment | `0x00DE` |
| `0x020B` | except if it has *selected properties* of documents or forms | `0x00DF` |
| `0x020C` | except if it has a size *in a specific range* | `0x00E0` |
| `0x020D` | except if it was received *in a specific date span* | `0x00E1` |
| `0x020E` | except where my name is in the Cc box | `0x00E2` |
| `0x020F` | except where my name is in the To or Cc box | `0x00E3` |
| `0x0210` | except if it uses the *form name* form | `0x00E4` |
| `0x0211` | except if the recipient's address contains *specific words* | `0x00E5` |
| `0x0212` | except if the sender's address contains *specific words* | `0x00E6` |
| `0x0213` | except if the message header contains *specific words* | `0x00E8` |
| `0x0214` | except through the *specified* account | `0x00EE` |
| `0x0215` | except if sender is in *specified* Address Book | `0x00F0` |
| `0x0216` | except if it is a meeting invitation or update | `0x00F1` |
| `0x0218` | except if it is of the *specific* form type (InfoPath) | `0x00F4` |
| `0x0219` | except if from RSS feeds with *specified text* in the title | `0x00F5` |
| `0x021A` | except if it is assigned to any category | `0x00F6` |
| `0x021B` | except if from any RSS feed | `0x00F7` |

### 7.6 Identifiers outside the tables

Some identifiers appear in Outlook's code but in no definition table, so no version can load a rule that contains them.

**Outlook 97's evaluator.** The client-side evaluator of Outlook 97 handles four conditions, and their exceptions, that the wizard can't create:

| ID | Exception | Test |
|---|---|---|
| `0x00D4` | `0x0200` ("except where my name is in the To box and it is a meeting") | my name is in the To box **and** it is a meeting |
| `0x00D5` | `0x0201` ("except where my name is not in the To box and it is a meeting") | my name is **not** in the To box **and** it is a meeting |
| `0x00DA` | `0x0206` ("except if sent to *people or public group* as Cc") | sent to the element's addresses as Cc recipients: the recipient test with `PR_RECIPIENT_TYPE` = 2 (`MAPI_CC`) |
| `0x00DB` | `0x0207` ("except if sent to *people or public group*") | sent to the element's addresses: the same recipient test as "sent to" (`0x00CC`), with type 1 (`MAPI_TO`) |

None of these IDs is in Outlook 97's definition table, so Outlook 97 can't load a file that contains them. Readers SHOULD still accept them.

**Server-rule and run code.** Outlook's code for server rules and for running rules also has cases for a few identifiers that no definition table has, such as `0x0134` and `0x0135`. None of them can appear in a file Outlook loads ([Server rules §3](ServerRules.md#3-server-forms-of-elements)).

**`0x00EA` (older form of junk senders)** is read as `0x00EB` ("suspected to be junk e-mail or from *Junk Senders*") by Outlook 2000–2013 ([§7.3](#73-conditions)). Any other unknown identifier makes the load fail ([§5.3](#53-element)).

### 7.7 Element definitions

Outlook keeps a *definition* for each element: its group, its parameter class, the masks that decide where the Rules Wizard offers it, whether it is client-only, and its UI text. Definitions aren't written to the file, but two things about them matter to readers and writers:

* The parameter class decides the layout of the element's parameters ([§8](#8-parameters)). The classes are numbered (the *kind*), and the numbers changed between versions, but they aren't written either.
* Outlook 2003 and 2007 discard an element whose *rule-set mask* lacks bit `0x2` when they load a file ([§5.3](#53-element)). Only the hidden actions `0x014D` ("have server reply using *a specific message*") and `0x014E` ("notify me using a .NET notification") have such a mask, so neither ever appears in a rule they save. Outlook 2010 removes the mask.

The rest is described in [Rules Wizard §1](RulesWizard.md#1-element-definitions).

---

## 8. Parameters

An element's parameters follow its NumberOfParameters ([§5.3](#53-element)). The element's identifier alone decides their layout: Outlook looks up the element's definition and creates the matching parameter class, so no class tag is written ([§1.3](#13-the-format-at-a-glance)). Class names in the headings below come from strings in Outlook's binaries, matched to parameters by name only **[Inferred]**.

**Reserved.** Every parameter starts with a 4-byte **Reserved** field. It MUST be `0` (all 791 parameters observed). It is a field of the common parameter base class: the constructor sets it to `0`, and the base `Serialize` writes it first. In Outlook 97–2002 the class also has a virtual getter and setter for it, but nothing in Outlook 97 calls them, and no parameter class reads or writes the field directly. Outlook 2003–2013 drop the getter and setter, and nothing else reads the field. It is reserved ([Appendix A](#appendix-a-open-questions)).

**Strings.** A String parameter is UTF-16 from version 1000000 and ANSI below it, whatever the element (Outlook 2002–2013). String8 parameters are ANSI in every generation.

**Checked versions.** Every parameter of Outlook 2000 and 2002 reads and writes these layouts. Outlook 2010's and 2013's serializers were checked field by field against them. Where a version changed which class an element uses, the section says so.

The tables below list the fields after Reserved.

### 8.1 EventParameter
Used by `0x0190` ("apply this rule *after the message arrives*").

| Field | Size | Description |
|---|---|---|
| Flags | 4 | When the rule runs. A bitmask; the UI joins set bits with " or ". `0x01` = after the message arrives, `0x04` = after I send the message, `0x08` = after the server receives the message. |

Observed values: `0x01` (272 rules) and `0x04` (6 rules).

Outlook 98–2013 read and write this parameter the same way. What each bit means was traced only in Outlook 97. Outlook 98's resources still offer all three choices, including "after the server receives the message". Outlook 2003–2013 offer only "after the message arrives" and "after I send the message" (Outlook 2010 and 2013 name their blank-rule templates "Apply rule on messages I receive" and "Apply rule on messages I send"). When Outlook 2003–2013 run rules, `0x01` matches received messages and `0x04` sent ones ([Running §1](Running.md#1-when-rules-run)).

### 8.2 ItemTypeParameter
Used by `0x0064` ("For each %s").

| Field | Size | Description |
|---|---|---|
| ItemTypes | 4 | A bitmask of the kinds of item the rule applies to, shown joined with " or ". Outlook 97 defines only `0x1` = "message", which is also the default. Its rule evaluator treats this element as always matching. Always `1` (278 of 278). |

Outlook 98–2013 read and write this parameter the same way, and every sample uses `1`. In Outlook 98–2002 the element definitions' item-type masks are `7`, `5` or `1`, reserving bits `0x2` and `0x4` that no item type ever uses. From Outlook 2003 every mask is `1` (or `0`), so "message" is the only item type left.

### 8.3 WordParameter
`CWordParameter`. Used by `0x00CD`–`0x00CF`, `0x00E5` ("with *specific words* in the recipient's address"), `0x00E6` ("with *specific words* in the sender's address"), `0x00E8` ("with *specific words* in the message header"), `0x00F5` ("from RSS feeds with *specified text* in the title") and their exceptions.

| Field | Size | Description |
|---|---|---|
| Value | variable | String. One word or phrase. |

An element has one WordParameter per word or phrase. The words are combined with OR. They are not delimited inside one string.

**One phrase or several.** Outlook 97 and 98 allow only **one phrase per condition**. The prompt is "Specify a word or phrase to search for…", typed into a single text box (the "Parameter Text" dialog), and the element reads at most one parameter. Several words per condition, stored as several parameters, came with Outlook 2000.

How Outlook matches the words is described in [Running §3.1](Running.md#31-words).

### 8.4 AddressParameter
Used by `0x00CB` ("from *people or public group*"), `0x00CC` ("sent to *people or public group*"), `0x012E` ("forward it to *people or public group*"), `0x013C` ("Cc the message to *people or public group*"), `0x0144` ("redirect it to *people or public group*"), `0x0147` ("forward it to *people or public group* as an attachment"), `0x01F7` ("except if from *people or public group*") and `0x01F8` ("except if sent to *people or public group*").

This is a serialized MAPI `ADRLIST`. For each `ADRENTRY`, Outlook 97 writes `ulReserved1` and `cValues`, copies the property array into one block (MAPI `ScCopyProps`), relocates its pointers to offsets from 0 (`ScRelocProps`), and writes the block's size and bytes. The uninitialised bytes inside `SPropValue`s are copied as they were in memory.

| Field | Size | Description |
|---|---|---|
| NumberOfEntries | 4 | `ADRLIST.cEntries`. |
| Entries | variable | NumberOfEntries × AdrEntry. |
| MatchAny | 4 | How the names are combined in the rule text: non-zero = " or ", `0` = " and ". Outlook 97 sets `1` for the conditions and exceptions (`0x00CB`, `0x00CC`, `0x01F7`, `0x01F8`) and `0` for the actions. All samples agree: 14 conditions with `1`, 11 actions with `0`. |
| IsCc | 4 | Set to `1` only for the "Cc the message to" action (`0x013C`); `0` otherwise. Outlook 97 never reads it: the Cc action always sets `PR_RECIPIENT_TYPE` to `MAPI_CC` itself. |

**AdrEntry**

| Field | Size | Description |
|---|---|---|
| Reserved1 | 4 | `ADRENTRY.ulReserved1`. Values vary and are often uninitialised memory; some are property tags such as `0x0FFF0102`. Readers MUST ignore it. Writers SHOULD write `0`. |
| NumberOfValues | 4 | `ADRENTRY.cValues`. |
| BlockSize | 4 | Size in bytes of the block that follows: the PropValue array plus the data area. |
| PropValues | 16 × NumberOfValues | SPropValue records. |
| Data | variable | Strings and binary values referenced by offsets. Offsets are measured from the first byte of PropValues. |

**SPropValue (16 bytes)**

| Field | Size | Description |
|---|---|---|
| PropTag | 4 | A property tag: the type in the low 16 bits and the ID in the high 16 bits ([MS-OXCDATA](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxcdata) §2.9). |
| AlignPad | 4 | `dwAlignPad`. Uninitialised memory. MUST be ignored and SHOULD be preserved when round-tripping. |
| Value | 8 | `union _PV`. Its encoding depends on the property type (below). |

| Type | Value encoding |
|---|---|
| `PT_LONG` (`0x0003`), `PT_ERROR` (`0x000A`) | `u32` in bytes 0–3. Bytes 4–7 are uninitialised. |
| `PT_BOOLEAN` (`0x000B`) | **[Inferred]** `u16` in bytes 0–1; the rest is uninitialised. Never observed. |
| `PT_UNICODE` (`0x001F`) | Bytes 0–3: offset to a NUL-terminated UTF-16 string in Data. |
| `PT_STRING8` (`0x001E`) | Bytes 0–3: offset to a NUL-terminated ANSI string in Data. |
| `PT_BINARY` (`0x0102`) | Bytes 0–3: `cb`. Bytes 4–7: offset to `cb` bytes in Data. |
| Others | Never observed. Readers SHOULD reject them. |

Observed property tags:

| Tag | Name | Notes |
|---|---|---|
| `0x0C150003` | PR_RECIPIENT_TYPE | `1` = MAPI_TO |
| `0x0FFE0003` | PR_OBJECT_TYPE | |
| `0x0FFF0102` | PR_ENTRYID | |
| `0x300B0102` | PR_SEARCH_KEY | |
| `0x3001001E/1F` | PR_DISPLAY_NAME | |
| `0x3002001E/1F` | PR_ADDRTYPE | |
| `0x3003001E/1F` | PR_EMAIL_ADDRESS | |
| `0x39000003` | PR_DISPLAY_TYPE | |
| `0x39FE000A` | PR_SMTP_ADDRESS | Stored as `PT_ERROR` `MAPI_E_NOT_FOUND` (`0x8004010F`) when unresolved. |
| `0x3A13001F`, `0x3D010102`, … | others | Copied from the address book entry. |

Even G2 files may use `PT_STRING8` properties. The property types are independent of the format generation.

**Versions.**

* **Outlook 98** copies each entry's properties with `ScDupPropset` and relocates them with `ScRelocProps`. It has no conversion step, since every format it writes is ANSI.
* **Outlook 2000** writes an entry with no values as BlockSize `0` and no block, and an empty address list as NumberOfEntries `0`. When showing the rule, it lists at most 10 names, and takes each name from a `PT_STRING8` PR_DISPLAY_NAME.
* **Outlook 2002–2013** copy and relocate the properties in the same way, giving the same layout as Outlook 97. When writing a format older than 1000000 they first convert the properties with `HrConvertSPropValues`, presumably to ANSI so that older versions can read them.

### 8.5 FlaggedForActionParameter
Used by `0x00D0` ("flagged for *action*") and `0x01FC` ("except if it is flagged for *action*"). This is the same class as FlagParameter ([§8.21](#821-flagparameter)), with IsCondition set.

| Field | Size | Description |
|---|---|---|
| Days | 4 | Unused by conditions. Always `0`. |
| Action | variable | String. Localised flag text, for example `Follow up`, `Forward`, `Do not Forward`, or `Any`. "Any" is only offered when IsCondition is set. |
| IsCondition | 4 | `1`: Outlook sets it for these elements. It switches the text from "*action* within *n* days" to just "*action*". |

Outlook 98–2013 read and write this layout the same way, and every version sets IsCondition to `1` for these conditions and leaves it `0` for the action `0x0131` ("flag message for *action in a number of days*").

### 8.6 ImportanceParameter
`CImportanceDialog`. Used by `0x00D2` ("marked as *importance*"), `0x0137` ("mark it as *importance*") and `0x01FE` ("except if it is marked as *importance*").

| Field | Size | Description |
|---|---|---|
| Importance | 4 | PR_IMPORTANCE value: `0` = low, `1` = normal, `2` = high. |

From Outlook 2003 the action `0x0137` ("mark it as *importance*") has a parameter class of its own: the same class as the conditions', created with a flag set in memory. The flag isn't written, so the layout is unchanged. Outlook 2007–2013 keep this.

Outlook 2013 doesn't offer the action for some stores ([Rules Wizard §1](RulesWizard.md#1-element-definitions)).

### 8.7 SensitivityParameter
`CSensitivityDialog`. Used by `0x00D3` ("marked as *sensitivity*"), `0x0138` ("mark it as *sensitivity*") and `0x01FF` ("except if it is marked as *sensitivity*").

| Field | Size | Description |
|---|---|---|
| Sensitivity | 4 | PR_SENSITIVITY value: `0` = normal, `1` = personal, `2` = private, `3` = confidential. |

### 8.8 CategoryParameter
`CCategoryParameter`. Used by `0x00D7` ("assigned to *category* category"), `0x0133` ("assign it to the *category* category") and `0x0203` ("except if it is assigned to *category* category").

| Field | Size | Description |
|---|---|---|
| Categories | variable | String. Category names separated by `;`. |

### 8.9 FormParameter
`CFormParameter`. Used by `0x00DF` ("with *selected properties* of documents or forms") and `0x020B` ("except if it has *selected properties* of documents or forms").

| Field | Size | Description |
|---|---|---|
| Forms | variable | String. Form display names separated by `;`. |
| NumberOfProperties | 2 (or 6) | Number of DocumentProperty records that follow, as a Count ([§2.1](#21-count)). Outlook 97 writes it with MFC `CArray::Serialize`, which is why it is narrower than NumberOfClasses. |
| Properties | variable | DocumentProperty records. |
| NumberOfClasses | 4 | Number of message classes that follow. This count is a `u32`. |
| Classes | variable | String8 (ANSI in every generation). Message classes, for example `IPM.Appointment`. |

**DocumentProperty**

| Field | Size | Description |
|---|---|---|
| Field | variable | String. Display name of the property, for example `Author`. Outlook limits it to 32 characters. |
| PropTag | 4 | A property tag. Observed IDs are named-property IDs (≥ `0x8000`, for example `0x81A2001F` and `0x8308001F`), which are **mapped per store**. The ID is not portable between stores; Field identifies the property (below). |
| StringMatch | 4 | `0` = contains, `1` = is exactly, `2` = does not contain. |
| StringValue | variable | String. |
| NumberMatch | 4 | `0` = equals, `1` = not equal to, `2` = at most, `3` = at least, `4` = more than, `5` = less than. |
| NumberValue1 | 4 | `i32`. Compared with 16-bit (`PT_I2`) properties. |
| NumberValue2 | 4 | `i32`. Compared with 32-bit (`PT_LONG`) properties. |
| BoolMatch | 4 | `0` = yes / true, `1` = no / false. |
| Unknown1 | 4 | **[Unknown]** Always `1`. Every constructor in Outlook 97–2013 sets it to `1`, and in every version checked nothing but serializing and copying uses it: the matching code never reads it, and the Document or Form Properties dialog never changes it ([Appendix A](#appendix-a-open-questions)). |
| DateMatch | 4 | `0` = before, `1` = after. |
| DateValue | 12 | OleDateTime. Defaults to the current time. |
| MatchIfMissing | 4 | `1`: if the message lacks this property, test the next property instead; any other value: a missing property fails the condition ([§8.9.1](#891-matchifmissing)). Only present when the stream's version is 970102 or later: every format except G0s, which is version 0. G0 streams count as 970102. Always `0` in the samples, none of which uses a document property. |

**Property IDs are remapped when loading.** When writing a format older than 1000000, Outlook 2002–2013 change a `PT_UNICODE` type in PropTag to `PT_STRING8`. When loading, Outlook 2002 maps Field back to a property ID in the current store by name, so the stored ID only matters if the name isn't found. Outlook 2003–2013 look Field up, ignoring case, in a table of the 26 Office document properties' menu texts ([§8.9.2](#892-office-document-properties)). On a match they use the property's internal name, and otherwise Field itself. They then call `GetIDsFromNames` with `MAPI_CREATE` on the default store's Inbox for that name in `PS_PUBLIC_STRINGS`, and replace PropTag's ID with the result, keeping its type. With `MAPI_CREATE` the name always gets an ID, so the stored ID is always replaced when the lookup succeeds.

#### 8.9.1 MatchIfMissing

* **Outlook 97**: non-zero means that a message without this property counts as a match; `0` means it does not. Every constructor sets it to `0`, and the dialog has no control for it, so Outlook 97 never creates a non-zero value. Its matcher does honour one.
* **Outlook 98–2013** test the properties in order and need all of them to match. MatchIfMissing changes that for the property and the one after it: if the message has the property, Outlook tests it and **skips the next property**; if the message doesn't have it, Outlook ignores it and tests the next property instead. So a pair means "test the property under its first name, or under its other name if the first is missing". A missing property without MatchIfMissing fails the condition. The matchers test for MatchIfMissing equal to `1`, not just non-zero, so any other value behaves like `0`. The pair behaviour therefore dates from Outlook 98, although only Outlook 2003 and later create pairs.
* **Outlook 2000–2013** write pairs: when the list is saved, a property whose MatchIfMissing is set is followed by a copy under the property's other name ([§8.9.2](#892-office-document-properties)) with MatchIfMissing `0`. Outlook 2000 never sets the field itself. Outlook 2003 and later set it when the user picks an Office document property from the dialog's menu ([Rules Wizard §2](RulesWizard.md#2-filling-in-parameters)).

#### 8.9.2 Office document properties

The document properties Outlook 2003 and later offer are named properties in `PS_PUBLIC_STRINGS` (`{00020329-0000-0000-C000-000000000046}`), each under two names: Office's internal name and its display name. The pair below is what MatchIfMissing links:

| Internal name | Display name | Type |
|---|---|---|
| `Author` | `Author` | `PT_UNICODE` |
| `ByteCount` | `Bytes` | `PT_LONG` |
| `Category` | `Category` | `PT_UNICODE` |
| `CharCount` | `Characters` | `PT_LONG` |
| `Comments` | `Comments` | `PT_UNICODE` |
| `Company` | `Company` | `PT_UNICODE` |
| `CreateDtmRo` | `Created` | `PT_SYSTIME` |
| `Subject` | `Document Subject` | `PT_UNICODE` |
| `EditTime` | `Edit Time` | `PT_UNICODE` |
| `HiddenCount` | `Hidden Slides` | `PT_LONG` |
| `Keywords` | `Keywords` | `PT_MV_UNICODE` |
| `LastAuthor` | `Last Saved By` | `PT_UNICODE` |
| `LastSaveDtm` | `Modified` | `PT_SYSTIME` |
| `LineCount` | `Lines` | `PT_LONG` |
| `Manager` | `Manager` | `PT_UNICODE` |
| `MMClipCount` | `Multimedia Clips` | `PT_LONG` |
| `NoteCount` | `Notes` | `PT_LONG` |
| `PageCount` | `Pages` | `PT_LONG` |
| `ParCount` | `Paragraphs` | `PT_LONG` |
| `PresFormat` | `Presentation Format` | `PT_UNICODE` |
| `LastPrinted` | `Printed` | `PT_SYSTIME` |
| `RevNumber` | `Revision Number` | `PT_UNICODE` |
| `SlideCount` | `Slides` | `PT_LONG` |
| `Template` | `Template` | `PT_UNICODE` |
| `Title` | `Title` | `PT_UNICODE` |
| `WordCount` | `Words` | `PT_LONG` |

The first property of a pair has the internal name's tag, and Field holds the menu text. The menu texts differ slightly from the display names, for example `Creation Time` and `Last Author`. Outlook 2007's, 2010's and 2013's tables are identical to Outlook 2003's.

#### 8.9.3 Comparisons

StringMatch, NumberMatch, BoolMatch and DateMatch apply by the type in PropTag: strings use StringMatch, integers NumberMatch (NumberValue1 for `PT_I2`, NumberValue2 for `PT_LONG`), booleans BoolMatch, and `PT_SYSTIME` DateMatch. The unused fields are written as zero or null. How Outlook compares the values is in [Running §3.2](Running.md#32-document-properties).

### 8.10 SizeParameter
`CSizeParameter`. Used by `0x00E0` ("with a size *in a specific range*") and `0x020C` ("except if it has a size *in a specific range*").

| Field | Size | Description |
|---|---|---|
| Minimum | 4 | Minimum size in KB. |
| Maximum | 4 | Maximum size in KB. |

### 8.11 TimeParameter
`CTimeParameter`. Used by `0x00E1` ("received *in a specific date span*") and `0x020D` ("except if it was received *in a specific date span*").

| Field | Size | Description |
|---|---|---|
| HasAfter | 4 | Non-zero if the "after" bound applies. |
| After | 12 | OleDateTime. |
| HasBefore | 4 | Non-zero if the "before" bound applies. |
| Before | 12 | OleDateTime. |

### 8.12 FormTypeParameter
Used by `0x00E4` ("uses the *form name* form"), `0x0210` ("except if it uses the *form name* form"), `0x00F4` (`CInfoPathFormTypeParameter`) and `0x0218` ("except if it is of the *specific* form type (InfoPath)").

| Field | Size | Description |
|---|---|---|
| Name | variable | String. Form display name. |
| MessageClass | variable | String8 (ANSI in every generation). For example `IPM.Contact` or `IPM.InfoPathForm.<id>$<id>`. |

### 8.13 SendersListParameter
Used by `0x00E9` ("from senders on my *Exception List*"), `0x00EB` ("suspected to be junk e-mail or from *Junk Senders*") and `0x00EC` ("containing adult content or from *Adult Content Senders*"). These elements exist only in G1.

| Field | Size | Description |
|---|---|---|
| Name | variable | String8. Observed values: `Exception List`, `Junk Senders` and `Adult Content Senders`. |

Outlook 98's junk filter isn't stored in the file ([Storage §2.3](Storage.md#23-outlook-98s-junk-filter)), and Outlook 98–2002 test the junk-mail conditions with a property of the message rather than this name ([Running §3.3](Running.md#33-junk-mail)).

Outlook 2010 and 2013 no longer have a class for these parameters: they read and write them with the plain String class, which reads the same single string. Their UI texts and the list names (`Exception List`, `Junk Senders`, `Adult Content Senders`) are gone from the resources.

### 8.14 RelevanceRangeParameter
Used by `0x00ED` ("with a relevance *in a specific range*").

| Field | Size | Description |
|---|---|---|
| Minimum | 4 | |
| Maximum | 4 | |

Outlook 2013's definition of `0x00ED` ("with a relevance *in a specific range*") no longer names this class, so Outlook 2013 reads and writes a `0x00ED` parameter as Reserved and one String, not this layout. The class still exists in Outlook 2013, but nothing uses it.

### 8.15 AccountParameter
`CAccountParameter`. Used by `0x00EE` ("through the *specified* account") and `0x0214` ("except through the *specified* account"), from Outlook 2000.

| Field | Size | Description |
|---|---|---|
| AccountName | variable | String: ANSI in the Outlook 2000 format, UTF-16 in G2. Outlook 2002–2007 write it as a String like any other: UTF-16 from version 1000000, ANSI below. |
| AccountStamp | variable | String8. **[Inferred]** An account identifier formatted as a signed decimal `i32`, for example `1285009305` or `-458008816`. |

Outlook matches accounts by this number, not by name ([Running §3.4](Running.md#34-accounts)).

### 8.16 ProfileStampParameter
Used by `0x00EF` ("on this computer only").

| Field | Size | Description |
|---|---|---|
| Stamp | 16 | GUID identifying the machine that "this computer" refers to. Files exported from the same machine carry the same GUID. |

Outlook 2003 and later match the condition when Stamp equals this computer's ID ([Running §3.5](Running.md#35-this-computer)). The ID also follows the rule to the Exchange server, in the server rule's provider name ([Server rules §2](ServerRules.md#2-uploading-rules)).

### 8.17 AddressBookParameter
`CABContListDialog`. Used by `0x00F0` ("sender is in *specified* Address Book") and `0x0215` ("except if sender is in *specified* Address Book").

| Field | Size | Description |
|---|---|---|
| EntryID | variable | Counted entry ID ([§2.3](#23-counted-entry-id)) of the address book container. |
| Name | variable | String: UTF-16 in G2, ANSI if written in an older format. |

Outlook 2003–2007 read and write it as Outlook 2002 does. How Outlook tests the condition is in [Running §3.6](Running.md#36-address-books).

### 8.18 AlertParameter
Used by `0x00F3` ("which is an *Alert E-mail*").

| Field | Size | Description |
|---|---|---|
| Name | variable | String: UTF-16 in every format that can hold `0x00F3` ("which is an *Alert E-mail*"), which needs version 1100000. The alert's name, a U+0001 character, and the text that identifies messages from the alert. |

Outlook splits Name at the last U+0001. The part before it is the alert's name, which Outlook shows in the rule. The part after it identifies messages from the alert: Outlook looks for it in their transport headers ([Running §3.7](Running.md#37-alert-e-mail)). In the sample (`Conditions/AlertCondition`) the second part is a GUID: `Alert from "Home" about "Documents (All Changes)"` U+0001 `{1D7EAA7A-B10A-485D-A8E9-5B3D611597E1}`.

### 8.19 FolderParameter
`CFolderParameter`. Used by `0x012C` ("move it to the *specified* folder") and `0x0139` ("move a copy to the *specified* folder").

| Field | Size | Description |
|---|---|---|
| FolderEntryID | variable | Counted entry ID of the target folder. |
| StoreEntryID | variable | Counted entry ID of the store that holds the folder. |
| FolderName | variable | String. Display name. |
| SecondaryStore | 4 | Added in version 970718, so it is absent in Outlook 97's formats (G0 and version stamp 970102) and in G0s (version 0). Outlook 98–2013 check the version; Outlook 2010 sets the field to `0` when loading an older stream. **[Unknown]** Always `1` observed. |

### 8.20 PathParameter / MessageParameter
`CLaunchFileParameter`, `CMessageParameter` and `CTemplateParameter`. Used by `0x012F` (template path), `0x0130` (alert message text), `0x0136` (sound file) and `0x0149` (application path). Outlook 2003's and 2007's hidden action `0x014D` ("have server reply using *a specific message*") uses the same layout.

| Field | Size | Description |
|---|---|---|
| Value | variable | String. |

### 8.21 FlagParameter
Used by `0x0131` ("flag message for *action in a number of days*").

| Field | Size | Description |
|---|---|---|
| Days | 4 | Due in this many days. Shown as "*action* within *days* days". |
| Action | variable | String. Flag text. |
| IsCondition | 4 | `0` for this action. See [§8.5](#85-flaggedforactionparameter). |

Outlook 98–2013 read and write this layout the same way. Outlook 2007–2013 offer `0x0131` ("flag message for *action in a number of days*") only for rules on sent messages ([§7.4](#74-actions)).

### 8.22 DeferParameter
`CDeferDialog`. Used by `0x013E` ("defer delivery by *a number of* minutes").

| Field | Size | Description |
|---|---|---|
| Minutes | 4 | |

### 8.23 CustomActionParameter
Used by `0x013F` ("perform *a custom action*").

| Field | Size | Description |
|---|---|---|
| Location | variable | String. The DLL implementing the action. |
| Name | variable | String. |
| Options | variable | String. |
| Value | variable | String. |

Outlook 2013 still reads and writes this layout, but no longer runs the action ([§7.4](#74-actions)).

### 8.24 RelevanceParameter
`CRelevanceParameter`. Used by `0x0145` ("add *number* to relevance").

| Field | Size | Description |
|---|---|---|
| Value | 4 | The number to add to the relevance. |

Outlook 2013 has no class for this layout: it reads and writes a `0x0145` ("add *number* to relevance") parameter as Reserved and one String, as it does `0x00ED` ("with a relevance *in a specific range*")'s ([§8.14](#814-relevancerangeparameter)).

### 8.25 ServerReplyParameter
`CReplyServerParameter`. Used by `0x0146` ("have server reply using *a specific message*").

| Field | Size | Description |
|---|---|---|
| MessageEntryID | variable | Counted entry ID of the reply template message, which is stored in the mailbox. |
| Name | variable | String: ANSI in the Outlook 2000 format, UTF-16 in G2. Outlook 2002–2007 write it as a String like any other: UTF-16 from version 1000000, ANSI below. |

The action is sent to the Exchange server ([Server rules §3](ServerRules.md#3-server-forms-of-elements)). When Outlook runs it itself, it uses its "reply using a template" handler ([Running §4.4](Running.md#44-server-reply)).

### 8.26 ScriptParameter
Used by `0x014B` ("run *a script*").

| Field | Size | Description |
|---|---|---|
| Name | variable | String: UTF-16 in G2, ANSI if written in an older format. The full name of the VBA procedure to run, such as `Project1.CustomMailMessageRule`. This is the string Outlook passes to VBA and shows in the rule. |
| Function | variable | String, like Name. A second string from the same macro-list entry. Outlook stores and copies it but doesn't use it to run the script. Observed equal to Name. |

Outlook 2002–2013 read and write it in this order, and run the procedure that Name names ([Running §4.3](Running.md#43-scripts)). The Rules Wizard fills in both strings from Outlook's list of VBA procedures ([Rules Wizard §2](RulesWizard.md#2-filling-in-parameters)).

### 8.27 FlagForFollowUpParameter
`ToDoActionDlg`. Used by `0x0151` ("flag message for *follow up at this time*").

| Field | Size | Description |
|---|---|---|
| FollowUp | 4 | `1` = today, `2` = tomorrow, `3` = this week, `4` = next week, `7` = no date, `10` = complete. |
| Action | variable | StringW. Flag text. |

What the action does to the message for each value is in [Running §4.1](Running.md#41-follow-up-flags). Values `1`–`6` select a start and due date from a table in Outlook, so `5` and `6` are also valid, though the samples use only `1`–`4`. **[Inferred]** `5` and `6` are this month and next month, from their table entries.

### 8.28 RetentionPolicyParameter
Used by `0x0153` ("apply retention policy: *retention policy*").

| Field | Size | Description |
|---|---|---|
| PolicyId | 16 | GUID of the retention tag. |
| Name | variable | StringW. |

New in Outlook 2010. The serializer writes Reserved, the 16-byte GUID and then Name as a String (so String8 below version 1000000, though `0x0153` itself needs `0x140000`). In memory the parameter also holds a retention period, which isn't written: Outlook fills it in from the policy. The UI text is "apply retention policy: %s", with the placeholder "retention policy". Outlook 2010's later updates also look the policy up by its GUID when loading. Outlook 2013 is the same as Outlook 2010. What the action does is in [Running §4.2](Running.md#42-retention-policies).

### 8.29 FlagColorParameter
Used by `0x0150` ("flag message with *a colored flag*").

| Field | Size | Description |
|---|---|---|
| Color | 4 | The flag colour, chosen from a list of six colours, `1`–`6`: a `PR_FLAG_ICON` value (`1` = purple … `6` = red), which the action writes to the message ([Running §4](Running.md#4-actions)). Outlook 2003 shows the colour's name, or nothing for `0`; a colour of `0` removes the colour. Outlook 2007's follow-up action writes `6` for its red flag, which confirms the numbering ([§8.27](#827-flagforfollowupparameter)). |

---

## 9. Versions and compatibility

### 9.1 Version words

From Outlook 2002, Outlook keeps two kinds of version in a G2 stream: RulesHeader.WriterVersion for the rules as a whole ([§4.1](#41-fields)), and RuleHeader.VersionStamp for each rule ([§5.1](#51-ruleheader)). Both are **version words**:

| Bits | Meaning |
|---|---|
| 0–23 | A version stamp ([§3.3](#33-version-stamps)). |
| 24–31 | That stamp's index in the writer's table of stamps. |

The index lets versions with different stamp schemes compare versions. A stamp missing from the reader's table gets the table's length as its index, and the table's entry there is `0`.

* **Outlook 2002**, when loading, raises the index until its table entry is at least the low 24 bits. It raises both parts when it upgrades the rules ([§9.3](#93-upgrading-rules)), and uses the stamp at the index as the default format for Export Rules ([§9.4](#94-exporting-to-older-formats)).
* **Outlook 2003** does the same. A stamp it doesn't know, such as Outlook 2010's `0x140000`, gets index 7, whose table entry is `0`, so its default export then writes a G0s stream ([§3.5](#35-version-0-streams-g0s)). A new profile starts with WriterVersion `0x0010C8E0` (index 0) until the index is next set.
* **Outlook 2007** knows Outlook 2010's stamp, because its table has `0x140000` at index 6. Otherwise it handles the word as Outlook 2003 does: the loader recomputes the index when the table entry is below the low 24 bits, the index is the position of an exact match or the table's length, 7, for an unknown stamp, and the entry at index 7 is `0`.
* **Outlook 2010 and 2013** handle the word the same way, with a table that is one entry longer: an unknown stamp gets index 8, whose entry is `0`.

Observed WriterVersion values:

| Writer | Target (VersionStamp) | WriterVersion |
|---|---|---|
| Outlook 2007 | 1200000 or 1000000 | `0x05124F80` (index 5, stamp 1200000) |
| Outlook 2007 (one file, `FormsException.rwz`) | 1000000 | `0x03124F80` (index 3) |
| Outlook 2010+ | `0x140000` or 1000000 | `0x06140000` (index 6, stamp `0x140000`) |
| Outlook 2010+ (`New732.rwz`) | 1000000 | `0x03140000` (index 3) |
| Outlook 2010+ (`Outlook2003All.rwz`) | 1100000 | `0x04140000` (index 4) |

### 9.2 A rule's own version

In G2, each rule carries its own version, and the rest of the rule is laid out for that version. A rule with an older stamp keeps that version's layout: for example, ANSI strings and no ServerRuleId or DataSize below 1000000. So one stream can mix layouts.

**Which version a rule is read and written at.**

* **Outlook 2002** uses the rule's stamp as it is when reading. When writing, it uses the older of the stream's version and the rule's.
* **Outlook 2003–2013** use the rule's stamp for both reading and writing, except when exporting, which uses the target version. Rules newer than their own version stay unparsed ([§5.5](#55-rules-from-newer-versions)).

**Which version a rule starts at.**

* **Outlook 2002** raises a rule's version when the user accepts a prompt that the rule needs a newer one, and when it upgrades all the rules ([§9.3](#93-upgrading-rules)).
* **Outlook 2003** starts new rules at 970812 and raises them as Outlook 2002 does.
* **Outlook 2007** starts new rules at 1000000 instead. The rule it creates itself gets 1200000 ([§4.3](#43-clearcategoriesrulecreated)). A rule below 980413 whose word condition has more than one word is raised to 980413.
* **Outlook 2010** still starts new rules at 1000000. The Clear categories rule still gets 1200000. A rule rebuilt from a server rule gets the version its actions need: 1200000 for "clear message's categories" and `0x140000` for a retention policy ([Server rules §5](ServerRules.md#5-reading-server-rules-back)).
* **Outlook 2013** is the same as Outlook 2010, except that it no longer makes the Clear categories rule.

**Outlook's own copy and exports.** The rules in the mailbox are loaded and saved in a different mode from Export Rules and Import Rules (Outlook 2002–2013):

* **Outlook's own copy** reads and writes every rule's VersionStamp and ServerRuleId, whatever the version. The rest of each rule follows its own stamp.
* **Export Rules** writes those two fields only from version 1000000, and writes the target version as each rule's VersionStamp. It leaves out the rules the target version can't hold ([§9.4](#94-exporting-to-older-formats)).
* **Import Rules** reads those two fields only from 1000000, and clears ServerRuleId.

So at the same G2 version, the mailbox copy and an export differ only in the rules' VersionStamps. The mailbox copy keeps each rule's own stamp (for example 1000000 for a new rule until it is upgraded), and an export writes the target stamp. **[Inferred]** That is why every sample, all of them exports, has rule stamps equal to the header's.

### 9.3 Upgrading rules

Outlook doesn't move rules to its own version by itself.

* **Outlook 2002** writes at most stamp 1000000. The Rules Wizard's Options dialog has a "Rules upgrade" section: "We recommend that you upgrade your rules for better performance, unless you also use a previous version of Outlook". Its "Upgrade Now" button is enabled only while the rules are older. After the user confirms, Outlook sets WriterVersion and every rule's VersionStamp to 1000000.
* **Outlook 2003**'s "Upgrade Now" raises WriterVersion and every rule's VersionStamp to 1100000, and **Outlook 2007**'s raises them in the same way.
* **Outlook 2010**'s raises them to `0x140000`, and the button is enabled only while WriterVersion is below `0x140000`. The Options dialog's advice now reads "unless you also use Outlook 2002 or earlier".
* **Outlook 2013** is the same as Outlook 2010, so it never raises rules to `0x150000`.

**Rules below 1000000.** When the rules are below 1000000 and there are rules, Outlook 2007–2013 ask before going on, and on Yes raise them to their own stamp: Outlook 2007 to 1200000, and Outlook 2010 and 2013 to `0x140000`. Cancel fails the operation. With no rules, Outlook raises the version without asking. Outlook 2007 doesn't count a first rule whose name starts with `#NET`, so a profile holding only the Net Folders rule is raised without asking; Outlook 2010 counts every rule. Outlook asks after loading the rules in three places: next to the Create Rule dialog, in Run Rules Now, and when Rules and Alerts loads a store's rules. Outlook 2007 asks in a fourth place too, which wasn't traced.

### 9.4 Exporting to older formats

When Outlook exports to an older format, it omits every rule that contains an element the older format cannot represent. Rules are dropped whole, never partially. For example, `Outlook2007_RunScript_98.rwz`, `…_FlagForFollowUp_2000.rwz` and `…_DisplayDesktopAlert_98.rwz` all contain zero rules. As a result, parameters that only exist in G2 are always written as UTF-16 in practice.

Outlook 2003 decides with a table of the version each element needs; every other element fits any version:

| Version needed | Elements |
|---|---|
| 980413 | `0x00ED` ("with a relevance *in a specific range*"), `0x0144`–`0x014A` |
| 1000000 | `0x00EE`–`0x00F0`, `0x014B` ("run *a script*"), `0x014C` ("mark it as read"), `0x0214` ("except through the *specified* account") |
| 1100000 | `0x00F1` ("which is a meeting invitation or update"), `0x00F3` ("which is an *Alert E-mail*"), `0x014F` ("display a Desktop Alert"), `0x0150` ("flag message with *a colored flag*"), `0x0216` ("except if it is a meeting invitation or update") |
| 1200000 | `0x00F4`–`0x00F7`, `0x0151` ("flag message for *follow up at this time*"), `0x0152` ("clear message's categories"), `0x0218`–`0x021B` (Outlook 2007) |
| `0x140000` | `0x0153` (Outlook 2010; otherwise the same as Outlook 2007's table). Outlook 2013's table is the same as Outlook 2010's. |

The account condition (`0x00EE`, `0x0214`) came with Outlook 2000, but Outlook 2003 only exports it for Outlook 2002 and later. Outlook 2000 itself decides differently ([§9.5](#95-how-outlook-2000-chooses-the-stamp)). When saving at a lower version than a rule's own, Outlook 2003 leaves the rule out unless all its elements fit that version.

**File types.**

* **Outlook 2002**'s Export Rules offers three: "Rules Wizard rules (\*.rwz)" writes the stamp at WriterVersion's index ([§9.1](#91-version-words)), "Outlook 2000 Compatible Rules Wizard rules" writes 980413, and "Outlook 98 Compatible Rules Wizard rules" writes 970812.
* **Outlook 2003–2013** offer four: "Rules Wizard rules (\*.rwz)", and "Outlook 2002", "Outlook 2000" and "Outlook 98 Compatible Rules Wizard rules (\*.rwz)" (1000000, 980413 and 970812). With an unknown WriterVersion, the first gives stamp 0, the G0s layout ([§3.5](#35-version-0-streams-g0s)).
* **Outlook 2010 and 2013** cap the first type at `0x140000`, so rules last upgraded by a newer Outlook (WriterVersion index 7, `0x150000`) are exported at `0x140000`. A WriterVersion with an unknown stamp still gives index 8 and stamp `0`, the G0s layout. The file-type names are no longer in Outlook's own resources; the dialog takes them from Office's shared strings.

**Checking descriptions first.** In Outlook 2007–2013, when the rule list has been changed in the dialog since it was last loaded, Export Rules first checks that every element with a parameter has a complete description. Otherwise it stops with an error message.

### 9.5 How Outlook 2000 chooses the stamp

Outlook 2000 keeps a "save version" with its rules and writes that stamp, not its own:

* A new profile starts at 970812. Loading or importing a stream sets it to the stream's stamp, or 970102 if that is lower (so G0 imports count as 970102).
* Some rules need 980413: rules using an element that Outlook 98 doesn't have (`0x00ED`, `0x00EE`, `0x0144`–`0x014A` and `0x0214`), or a word condition with more than one word. When the user creates or imports one of these while the save version is below 980413, Outlook asks first. One message says the rule "will not be compatible with Outlook versions before Outlook 2000"; another says that a rule searching for several words or phrases can't be used by an earlier version. If the user agrees, the save version becomes 980413 for good.
* When saving at a version below 980413, Outlook leaves out every rule that contains an Outlook 2000-only element, and NumberOfRules counts only the rules written. When the version is exactly 970812, each element is written with at most one parameter: NumberOfParameters is `1` and only the first parameter follows ([§5.3](#53-element)).
* Export offers two file types: "Rules Wizard rules (\*.rwz)" uses the current save version, and "Outlook 98 Compatible Rules Wizard rules (\*.rwz)" uses 970812.

That is why most streams written by Outlook 2000 carry 970812. In the samples, the Outlook 2000 files saved with the default settings are 970812, except the one with the Outlook 2000-only "print it" action (980413). The same rules exported for Outlook 98 have 970812, and that "print it" file has no rules at all.

Outlook 2002 and later replace the save version with WriterVersion ([§9.1](#91-version-words)) and each rule's own VersionStamp ([§9.2](#92-a-rules-own-version)). They keep the per-element version check: a rule is left out of an export to a version that can't hold its elements ([§9.4](#94-exporting-to-older-formats)), and an export at exactly 970812 writes at most one parameter per element.

Outlook 2007 doesn't follow these rules when exporting: its exports "for Outlook 98" keep every word of a word condition as a separate parameter. Writers that target Outlook 97 or 98 SHOULD write at most one parameter per element, because those versions read only one ([§5.3](#53-element)).

---

## 10. Reading and writing

### 10.1 Reading

1. If the stream is shorter than 4 bytes, it is G0. Otherwise identify the generation and version from the first u32 ([§3.2](#32-identifying-the-format)).
2. Read the RulesHeader for that generation ([§4](#4-rulesheader)). In G0 only the rule count is present.
3. For each rule, read the RuleHeader ([§5.1](#51-ruleheader)). Its fields depend on the generation and version ([§3.4](#34-version-dependent-fields)), and in G2 on the rule's own version ([§9.2](#92-a-rules-own-version)).
4. In G2, use DataSize to find the end of the rule. If the rule's version is newer than the reader supports, or the rule contains an element the reader doesn't know, keep the rule's bytes and move on ([§5.5](#55-rules-from-newer-versions)). A DataSize of `0` means the rule has no elements.
5. Read each element: the object tag ([§2.5](#25-object-tag)), the identifier ([§7](#7-elements)), NumberOfParameters, and the parameters for that identifier ([§8](#8-parameters)). Strings are ANSI or UTF-16 by generation ([§2.2](#22-string)).
6. Except in G0, read the RulesFooter ([§6](#6-rulesfooter)). The stream should then end.

Readers SHOULD be lenient where Outlook is: treat any non-zero Enabled as enabled and any non-zero RunError as an error, accept any value in the [Unknown] fields, ignore `SPropValue.AlignPad` and `AdrEntry.Reserved1`, accept zero or one Reserved parameter on `0x00F7` ("from any RSS feed") and `0x021B` ("except if from any RSS feed"), and read `0x00EA` (older form of junk senders) as `0x00EB` ("suspected to be junk e-mail or from *Junk Senders*").

### 10.2 Writing

To produce a stream that Outlook accepts:

1. Choose a generation and VersionStamp. Unless backward compatibility is needed, write G2 with VersionStamp `0x00140000` and WriterVersion `0x06140000`.
2. Header Unknown1–3 and ClearCategoriesRuleCreated = `0`, ServerRulesOutOfDate = `0`, ServerUpdateMode = `0`, PromptToConvertInboxAssistantRules = `1`, ConvertInboxAssistantRules = `1`, ExtraDataSize = `0` with no ExtraData.
3. For each rule, write RuleHeader.VersionStamp = the stream's VersionStamp, and compute DataSize as defined in [§5.1](#51-ruleheader).
4. Write `CRuleElement`'s class descriptor before the stream's first element, and `0x8001` before every other element.
5. Every rule MUST begin with elements `0x0190` ("apply this rule *after the message arrives*") and `0x0064` ("for each *message*").
6. Write all Reserved fields as `0`. Write SPropValue.AlignPad and AdrEntry.Reserved1 as `0`, or preserve the original values.
7. Write the footer with Status = null (`2`) and Date = `0.0` unless a real timestamp is known.
8. When writing an older format, follow [§9.4](#94-exporting-to-older-formats) and [§9.5](#95-how-outlook-2000-chooses-the-stamp): leave out rules that use elements the format doesn't have, and write at most one parameter per element for Outlook 97 and 98.

---

## Appendix A. Open questions

The details of each search are in [Decompilation notes](Decompilation.md#appendix-open-questions).

1. **RulesHeader Unknown1–3 and the footer's Unknown.** Outlook 97–2013 only preserve them (Outlook 2002 and later discard Unknown1). Searches of Outlook 2007's, 2010's and 2013's code found only the loader, saver, constructor and copy routine ([§4.2](#42-unknown13)). What wrote the `1`s reported in the mailbox copy is still unknown; a version after Outlook 2013 is now the most likely source.
2. **What later versions put in the header's ExtraData.** Outlook 2002–2013 only preserve it, and Outlook 2010 and 2013 write none of their own ([§4.6](#46-extradata)).
3. **Whether versions after Outlook 2013 give the parameter Reserved field a meaning.** Outlook 2007's, 2010's and 2013's base parameter classes still only set it to `0` and serialize it ([§8](#8-parameters)). (Outlook 2003 writes MatchIfMissing `1` for document properties, [§8.9](#89-formparameter).)
4. **Whether `PidTagRwRulesStream` differs from an exported `.rwz`.** Answered for Outlook 2003, 2010 and 2013: the same code writes both, in different modes, and at the same version they differ only in the rules' VersionStamps ([§9.2](#92-a-rules-own-version)). Versions after Outlook 2013 weren't checked.
5. **DocumentProperty Unknown1.** Always `1`. Every constructor in Outlook 97–2013 sets it, and only the serializer and copy routine use it ([§8.9](#89-formparameter)).
6. **Whether stamp `0x150000` changes the layout.** Stamp `0x140000` doesn't: Outlook 2010 reads and writes it with the Outlook 2002 layout. Outlook 2013 doesn't write `0x150000` at all: it still writes `0x140000`, reads a stream stamped `0x150000` with the Outlook 2002 layout, and keeps a rule stamped `0x150000` unparsed ([§3.3](#33-version-stamps)). So no version studied gives `0x150000` a layout, and readers can treat it as G2.
7. **Rule Flags bits `0x1` and `0x2`.** Outlook 97–2013 never set them (in Outlook 2013 the whole `OUTLOOK.EXE` was searched). Outlook 2010 and 2013 can still take them from offset `0x18` of an Outlook 98 or 2000 server rule's provider data; Outlook 2003–2013 forgive errors in single rules that have them; and every version from 98 to 2013 clears all the flags when the user edits such a rule ([§5.2](#52-rule-flags)). That supports the guess that they mark errors, but nothing studied writes them.
8. **The two extra flags in each element definition.** Outlook 97's definitions have two flags that no code in Outlook 97, 98 or 2000 reads ([Decompilation §3.1](Decompilation.md#31-element-definitions)). The first is now answered: in Outlook 2010 and 2013 it means "the wizard may offer this element" ([Rules Wizard §1](RulesWizard.md#1-element-definitions)). The second is still unexplained. Outlook 97–2003 never read it, Outlook 2003 and later no longer copy it into their definitions, and although Outlook 2010 changes it for 41 elements, it still has no effect.
9. **The field Outlook 2002 added to its definitions.** Answered for Outlook 2010 and 2013: it marks redirect and server reply, which the wizard hides when the store has no Exchange server rules ([Rules Wizard §1](RulesWizard.md#1-element-definitions)). Outlook 2002 and 2003 never use it.
10. **Bit `0x1` of the rule-set mask** that Outlook 2003 added ([Rules Wizard §1](RulesWizard.md#1-element-definitions)). Outlook 2003 and 2007 never use it, and the Out of Office rules don't explain it ([Server rules §7](ServerRules.md#7-inbox-assistant-and-out-of-office-rules)). Only `0x014D` ("have server reply using *a specific message*") and `0x014E` ("notify me using a .NET notification") have it, and nothing creates them. Outlook 2010 removes the mask, `0x014D` and `0x014E` altogether, so it can't answer the question either. Neither can Outlook 2013.

## Appendix B. Corrections to earlier notes

`docs/RWZ Format.docx` contains earlier experimental notes on the format. Where they disagree with this document, this document has been checked against the samples and takes precedence.

* **0x0064 "unknown element".** It is "For each *message*" ([§8.2](#82-itemtypeparameter)).

These items in `docs/RWZ Format.docx` contradict the sample corpus:

* **"Extended" field.** This is NumberOfParameters ([§5.3](#53-element)). It can be 2 or more for word lists.
* **"Separator" / "Padding" / "Class Name" in the rule header.** These are the MFC object tag and the class schema of the next element ([§2.5](#25-object-tag)). They are part of each element's encoding.
* **"Unknown3 MUST NOT be present in Outlook 2000 and earlier."** That field is the rule's Flags, which G1 (Outlook 98/2000) has.
* **"Unknown8 always one … Unknown4–6 unknown."** Unknown7 (PromptToConvertInboxAssistantRules) is also always `1`, and Unknown4–6 are ClearCategoriesRuleCreated, ServerRulesOutOfDate and ServerUpdateMode, which follow the writer ([§4.7](#47-values-written-by-each-version)).
* **Fixed property IDs `0x8222`–`0x823A` for document properties.** Observed IDs differ because they are named-property mappings ([§8.9](#89-formparameter)).
* **PropertyValueArray "Unknown, always zero".** It is `ADRENTRY.ulReserved1`, and is usually non-zero garbage ([§8.4](#84-addressparameter)).
* **Signature (VersionStamp) format "major × 100000 + minor/build".** Only true for stamps 1000000–1200000 ([§3.3](#33-version-stamps)).
