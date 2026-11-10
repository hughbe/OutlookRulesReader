# Outlook Rules Wizard (.rwz) File Format

This document specifies the binary format used by Microsoft Outlook to store client-side rules ("Rules Wizard" rules), both in exported `.rwz` files and in the `PidTagRwRulesStream` property. It is a reverse-engineered specification: nothing here is published by Microsoft.

## Status of this document

Every statement in this document has one of three confidence levels:

| Marker | Meaning |
|---|---|
| *(none)* | **Verified.** Checked against every sample file in `Tests/OutlookRulesReaderTests/Resources` (330 files written by Outlook 97, 98, 2000, 2003, 2007 and 2019) by an independent parser. |
| **[Inferred]** | Consistent with all samples, but the *meaning* comes from interpretation (for example, a match with an MFC or MAPI structure), not observation. |
| **[O97]** | Read from the Outlook 97 Rules Wizard's code (`docs/Internals/RULESWIZ.DLL`, disassembled). This shows how Outlook 97 writes and uses the field. Later versions are assumed to keep the meaning wherever the samples agree. See [Appendix D](#appendix-d-findings-from-ruleswizdll). |
| **[O98]** | Read from Outlook 98's code (`OUTLLIB.DLL` from the Outlook 98 CD, disassembled). See [Appendix E](#appendix-e-findings-from-outlook-98). |
| **[O2000]** | Read from Outlook 2000's code (`OUTLLIB.DLL` and its Turkish resource DLL `1055/OUTLLIBR.DLL` from an Outlook 2000 CD, disassembled). See [Appendix F](#appendix-f-findings-from-outlook-2000). |
| **[Unknown]** | The field's layout is known but its meaning is not. Observed values are listed. |

Writers SHOULD reproduce observed values for fields marked [Unknown]. Readers SHOULD accept any value.

`docs/RWZ Format.docx` contains earlier experimental notes. Where those notes and this document disagree, this document has been checked against the sample corpus and takes precedence (see [Appendix C](#appendix-c-corrections-to-earlier-notes)).

---

## 1. Introduction

An Outlook rule is a set of conditions, actions and exceptions that Outlook evaluates against messages as they arrive or are sent<sup>[1]</sup>. Rules began in Outlook 97 as the *Rules Wizard* add-in (`RULESWIZ.DLL`)<sup>[2]</sup> and were built into Outlook from Outlook 98 onwards<sup>[3]</sup>.

### 1.1 Storage

Where Outlook stores rules depends on its version<sup>[4]</sup>:

* **Outlook 2002 and later.** Rules are stored in the mailbox or PST<sup>[5]</sup>. The rules stream is the `PidTagRwRulesStream` (`PR_RW_RULES_STREAM`, `0x68020102`) property of a message named `Outlook Rules Organizer`, whose message class is `IPM.RuleOrganizer`<sup>[6]</sup>. The message is in the associated contents table<sup>[7]</sup> of the Inbox folder.

  ![Rules Stream](assets/RulesStream.png)

* **Outlook 2000 and earlier.** Rules are stored on disk at `%APPDATA%\Microsoft\Outlook\<ProfileName>.rwz`.

Users can also import and export rules as `.rwz` files. When exporting, Outlook 2007 offers to write the file in the current format or in a format for Outlook 2002, 2000 or 98:

![Rules Export](assets/RulesExport.png)

The server treats this format as client-specific and opaque<sup>[8]</sup>. `.rwz` files and `PidTagRwRulesStream` values share the format defined here. A few header values are known to differ between them.

### 1.2 Glossary

**ANSI string**: a sequence of 8-bit characters in the writer's code page. In practice this is ASCII or Windows-1252.

**COleDateTime**: the MFC date/time class. See [§2.4](#24-oledatetime).

**DATE / OLE Automation date**: an 8-byte IEEE double holding the number of days since 1899-12-30 00:00. The fractional part is the time of day. See [MS-DTYP] and [MS-OAUT].

**Format generation**: one of the four layouts described in [§3](#3-format-generations).

**Signature**: the version stamp at the start of the stream. See [§4.1](#41-version-stamps).

**UTF-16**: UTF-16 little-endian, with no byte order mark and no terminating NUL unless stated otherwise.

**MAY, SHOULD, MUST, SHOULD NOT, MUST NOT**: as defined in [RFC2119].

### 1.3 References

* [MS-DTYP] Microsoft, "Windows Data Types". https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp
* [MS-OXCDATA] Microsoft, "Data Structures". https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxcdata
* [MS-OXPROPS] Microsoft, "Exchange Server Protocols Master Property List".
* [MS-OXORULE] Microsoft, "Email Rules Protocol".
* [MFC-CArchive] Microsoft, "CArchive Class" and Technical Note TN002, "Persistent Object Data Format".
* [RFC2119] Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, March 1997.

### 1.4 Conventions

* All integers are **little-endian**.
* `u8`, `u16` and `u32` are unsigned integers of 1, 2 and 4 bytes. `i32` is a signed 32-bit integer and `f64` is an IEEE 754 double.
* Structures are packed. There is no alignment padding anywhere in the stream.
* Field sizes are shown in parentheses, for example **Count (2 bytes)**. "Variable" means the size depends on the content.

---

## 2. Common data types

### 2.1 The stream is an MFC `CArchive`

The format is the output of MFC's `CArchive` serialization **[O97]**. Most of the structure follows from this:

* Rule elements are `CObject`s of class `CRuleElement` (runtime-class schema 0), written with `CArchive::WriteObject`. Each element is preceded by an object tag ([§2.5](#25-object-tag)).
* A rule (`CRule`) writes its name, Enabled, Unknown1 and ServerRule, then its element list, a `CObList`. `CRule` is not written as an object, so it has no tag.
* `CRuleElement::Serialize` writes the element ID, a has-parameter flag ([§4.3.2](#432-element)), and then calls the parameter object's own `Serialize`.
* Length-prefixed strings use `CString`'s length encoding ([§2.2](#22-string)).
* Dates are written with `operator<<(CArchive&, COleDateTime)` ([§2.4](#24-oledatetime)).
* `RULESWIZ.DLL` (Outlook 97) statically links MFC. It contains the class names `CObject`, `CArchive`, `CRule`, `CRuleComponent` and `CRuleElement`.

Parameter objects all derive from one base class, whose `Serialize` writes the Reserved field ([§6](#6-parameters)). Each element's definition says which parameter class to create, so the class is never written: parameters carry no class tag. Most string parameters (words, categories, paths, messages) share a single "Reserved + CString" class **[O97]**. Class names such as `CWordParameter` and `CFolderParameter` come from Outlook's binaries (`docs/Rules Sever Side.xlsx`).

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

In this document, **String** means "String8 in the ANSI generations and StringW in the Unicode generation" ([§3](#3-format-generations)). StringW and String8 mean that encoding in every generation.

### 2.3 Counted entry ID

| Field | Size | Description |
|---|---|---|
| Size | 4 | Length of EntryID in bytes. |
| EntryID | Size | A MAPI entry ID ([MS-OXCDATA] §2.2). |

### 2.4 OleDateTime

The serialized form of an MFC `COleDateTime` (12 bytes).

| Field | Size | Description |
|---|---|---|
| Status | 4 | `0` = valid, `1` = invalid, `2` = null. Only `0` and `2` have been observed. |
| Date | 8 | An OLE Automation date (`f64`). |

When Status is null, Date is `0.0`.

### 2.5 Object tag

Every rule element is preceded by an MFC object tag (`u16`):

| Value | Meaning |
|---|---|
| `0xFFFF` | **New class** (`wNewClassTag`). A class descriptor follows: Schema (`u16`, always `0`), NameLength (`u16`, always `12`), Name (NameLength ANSI bytes, always `CRuleElement`). |
| `0x8001` | **Class reference** (`wClassTag \| 1`). The object's class is entry 1 of the archive's class map, which is `CRuleElement`. |

The class descriptor is written once per stream, before the first element of the first rule. Every later element in the stream, including the first element of rules 2…N, uses `0x8001`. A rule with zero elements writes no tag.

The earlier notes described these tags as a "separator" in the rule header. They are part of each element's encoding.

MFC can also emit `0x7FFF` (big object tag) and object back-references (`0x0001`–`0x7FFE`). Neither has been observed. Readers MAY treat them as corruption.

**[O2000]** Outlook 2000 no longer uses MFC's `CArchive`, but its own archive class writes the same bytes. Its writer emits the class descriptor once per archive (a flag on the archive object) and `0x8001` after that. Its reader is looser than MFC's: after `0xFFFF` it reads Schema, NameLength and the name into a 456-byte buffer without checking the name, and it treats **any** other tag as a reference to `CRuleElement`.

### 2.6 GUID

16 bytes, laid out as a Windows `GUID` ([MS-DTYP] §2.3.4).

---

## 3. Format generations

The first four bytes of the stream identify one of four layouts:

| Generation | First u32 | Written by | Strings | Library (`OutlookRulesVersion`) |
|---|---|---|---|---|
| **G0** (Outlook 97) | anything not listed below | Outlook 97's Export Rules | ANSI | `.outlook97` |
| **G0s** (signature 0) | `0x00000000` | unknown; see note | ANSI | `.signatureZero` |
| **G1** (ANSI) | `970102`, `970812`, `980413` | Outlook 97's profile copy; Outlook 98; Outlook 2000 (usually as `970812`, see [§4.1](#41-version-stamps)); Outlook 2002+ exporting "for Outlook 98/2000" | ANSI | `.outlook97Profile`, `.outlook98`, `.outlook2000` |
| **G2** (Unicode) | `1000000`, `1100000`, `1200000`, `0x00140000` | Outlook 2002 and later | UTF-16 | `.outlook2002`, `.outlook2003`, `.outlook2007`, `.outlook2010` |

Within G1, signature 970102 lacks two fields that 970812 has ([§4.1.1](#411-version-dependent-fields)).

**G0** has no signature. Its first 2 bytes are the rule count, and its next byte is the first rule name's length. Every Outlook 97 sample starts `01 00` (one rule). **[O97]** G0 is Outlook 97's **Export Rules** format: the exporter writes the rule count with `CArchive::WriteCount` and then each rule, with no header or footer. The rules Outlook 97 keeps in the profile use the G1 layout with Signature 970102 ([§4.1](#41-version-stamps)).

A G0 stream can only begin with four zero bytes if it has no rules, and then it is only 2 bytes long (`00 00`). Readers MUST therefore treat a stream shorter than 4 bytes as G0.

Readers SHOULD identify the format by **range** rather than by exact stamp, as Outlook does (Outlook 98 accepts any stamp from 960706 to 970812 **[O98]**). Later builds of a version may then write slightly different stamps, and Outlook 2013 knows `0x150000`. A G0 stream's first four bytes are its rule count, then the first rule name's length and first character (or the Enabled field when the name is empty). They are therefore either below 960706 or at least `0x01000000`, never inside a stamp range:

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

Stamps 960706–970811 also cover pre-release builds whose footer or folder fields differ ([§4.1.1](#411-version-dependent-fields)). No such file has been seen.

**G0s** has two samples (`Versions/Outlook2003/*`). The layout is G1 with Signature = 0 and without Rule Unknown3. The missing field follows from its signature: rule Flags (Unknown3) are only read and written when the version is 970812 or later, and 0 is below that **[O98]**. **[Unknown]** which product writes it. It may be the `PidTagRwRulesStream` form described in [§1.1](#11-storage).

Field presence by generation:

| Structure / field | G0 | G0s | G1 (970102) | G1 (970812+) | G2 |
|---|---|---|---|---|---|
| RulesHeader.Signature | – | ✓ (=0) | ✓ | ✓ | ✓ |
| RulesHeader.WriterVersion | – | – | – | – | ✓ |
| RulesHeader.Unknown1–8 | – | ✓ | ✓ | ✓ | ✓ |
| RulesHeader.Unknown9 | – | – | – | – | ✓ |
| RuleHeader.Signature | – | – | – | – | ✓ |
| RuleHeader.Unknown3 (Flags) | – | – | – | ✓ | ✓ |
| RuleHeader.Unknown4, DataSize | – | – | – | – | ✓ |
| Folder parameter's SecondaryStore | – | ✓ | – | ✓ | ✓ |
| RulesFooter | – | ✓ | ✓ | ✓ | ✓ |

---

## 4. Top-level structure

```
Stream := RulesHeader  Rule[RulesHeader.NumberOfRules]  RulesFooter?
```

The footer is absent in G0. After the footer the stream MUST end: no sample has trailing bytes.

### 4.1 Version stamps

Outlook identifies format versions with 24-bit "version stamps". Up to Outlook 2000 a stamp is a `YYMMDD` build date. From Outlook 2002 it is the product's major version × 100000. From Outlook 2010 it is the major version written as hex digits (`0x14` = 14):

| Index | Stamp (decimal) | Stamp (hex) | Meaning |
|---|---|---|---|
| — | 960706 | `0x0EA8C2` | The oldest version Outlook 97 accepts in its profile copy of the rules; anything older is rejected **[O97]**. |
| — | 960723 | `0x0EA8D3` | Footer TemplateDirectory added **[O97]**. |
| — | 960820 | `0x0EA934` | Footer Timestamp added **[O97]**. |
| — | 960918 | `0x0EA996` | "Version 960918" appears in `RULESWIZ.DLL`'s About text. Never written to files. |
| — | 960925 | `0x0EA99D` | Footer Unknown added **[O97]**. |
| 0 | 970102 | `0x0ECD76` | **Outlook 97.** The stamp `RULESWIZ.DLL` writes to its profile copy of the rules (the G1 layout), and the newest version it accepts **[O97]**. DocumentProperty MatchIfMissing ([§6.9](#69-formparameter)) was added in this version. Its exports (G0) have no stamp; Outlook 98 imports them as version 970102. Never observed in a sample. |
| — | 970718 | `0x0ECFDE` | Folder parameter SecondaryStore added **[O98]**. |
| 1 | 970812 | `0x0ED03C` | **Outlook 98.** Adds the rule Flags field ([§4.3.1](#431-ruleheader)) **[O98]**. Outlook 98 accepts 960706–970812 and doesn't know 980413. |
| 2 | 980413 | `0x0EF5BD` | **Outlook 2000.** Adds no fields: the layout is the same as 970812, but Outlook 2000 reads NumberOfParameters as a count ([§4.3.2](#432-element)) and defines more elements ([§5](#5-element-identifiers)). It refuses stamps of 1000000 or more and warns about stamps newer than its own **[O2000]**. Outlook 2000 only writes this stamp once the rules need it; otherwise it writes 970812 ([§4.1.2](#412-how-outlook-2000-chooses-the-stamp)). |
| 3 | 1000000 | `0x0F4240` | Outlook 2002 (v10). |
| 4 | 1100000 | `0x10C8E0` | Outlook 2003 (v11). |
| 5 | 1200000 | `0x124F80` | Outlook 2007 (v12). |
| 6 | 1310720 | `0x140000` | Outlook 2010 (v14) and later. Outlook 2019 still writes this stamp. |
| 7 | 1376256 | `0x150000` | v15 (Outlook 2013). Known to Outlook; never observed in a file. |

Indices 0–7 match the order of a table found in a disassembly of a modern 64-bit Outlook build (`docs/Internals/RWZ Decompilation Notes.docx`). The index is used by RulesHeader.WriterVersion ([§4.2](#42-rulesheader)).

#### 4.1.1 Version-dependent fields

Outlook 97 and 98 read and write these fields only when the stream's version is at least the stamp shown **[O97]** **[O98]**. No other field depends on the version. The format generations of [§3](#3-format-generations) differ in more ways than this, because Outlook 2002 also changed the string encoding and the rule header.

| Since | Field | Section |
|---|---|---|
| 960723 | Footer TemplateDirectory | [§4.4](#44-rulesfooter) |
| 960820 | Footer Timestamp | [§4.4](#44-rulesfooter) |
| 960925 | Footer Unknown | [§4.4](#44-rulesfooter) |
| 970102 | DocumentProperty MatchIfMissing | [§6.9](#69-formparameter) |
| 970718 | Folder parameter SecondaryStore | [§6.19](#619-folderparameter) |
| 970812 | Rule Flags (RuleHeader Unknown3) | [§4.3.1](#431-ruleheader) |

Unsigned (G0) streams count as version 970102. Outlook 2000 reads and writes the same fields under the same checks **[O2000]**.

#### 4.1.2 How Outlook 2000 chooses the stamp

**[O2000]** Outlook 2000 keeps a "save version" with its rules and writes that stamp, not its own:

* A new profile starts at 970812. Loading or importing a stream sets it to the stream's stamp, or 970102 if that is lower (so G0 imports count as 970102).
* Some rules need 980413: rules using an element that Outlook 98 doesn't have (`0x00ED`, `0x00EE`, `0x0144`–`0x014A` and `0x0214`), or a word condition with more than one word. When the user creates or imports one of these while the save version is below 980413, Outlook asks first. One message says the rule "will not be compatible with Outlook versions before Outlook 2000"; another says that a rule searching for several words or phrases can't be used by an earlier version. If the user agrees, the save version becomes 980413 for good.
* When saving at a version below 980413, Outlook leaves out every rule that contains an Outlook 2000-only element, and NumberOfRules counts only the rules written. When the version is exactly 970812, each element is written with at most one parameter: NumberOfParameters is `1` and only the first parameter follows ([§4.3.2](#432-element)).
* Export offers two file types: "Rules Wizard rules (\*.rwz)" uses the current save version, and "Outlook 98 Compatible Rules Wizard rules (\*.rwz)" uses 970812.

That is why most streams written by Outlook 2000 carry 970812. In the samples, the Outlook 2000 files saved with the default settings are 970812, except the one with the Outlook 2000-only "print it" action (980413). The same rules exported for Outlook 98 have 970812, and that "print it" file has no rules at all.

Outlook 2007 doesn't follow these rules: its exports "for Outlook 98" keep every word of a word condition as a separate parameter. Writers that target Outlook 97 or 98 SHOULD write at most one parameter per element, because those versions read only one ([§4.3.2](#432-element)).

### 4.2 RulesHeader

| Field | Size | Generations | Description |
|---|---|---|---|
| Signature | 4 | G0s, G1, G2 | The target format's version stamp ([§4.1](#41-version-stamps)), or `0` in G0s. Writers converting between formats SHOULD write the stamp of the target format; readers SHOULD preserve an unrecognised stamp within a known range ([§3](#3-format-generations)). |
| WriterVersion | 4 | G2 | Bits 0–23: the version stamp of the Outlook that wrote the stream. Bits 24–31: an index into the table in [§4.1](#41-version-stamps). **[Unknown]** what the index means; it equals either the writer's index or the Signature's index. |
| Unknown1 | 4 | not G0 | Writers SHOULD write `0`; readers MUST accept any value. Always `0` in the samples, but hughbe/OutlookRulesReader#2 reports fields like these being `1` in the copy of the rules stored in the mailbox. **[O97]** **[O98]** **[O2000]** Outlook loads and saves Unknown1–4 unchanged; nothing else reads or writes them, and new profiles start with 0. |
| Unknown2 | 4 | not G0 | As Unknown1. |
| Unknown3 | 4 | not G0 | As Unknown1. |
| Unknown4 | 4 | not G0 | **[Unknown]** `0` or `1`. Outlook 97 never changes it from 0; Outlook 2003/2007 write `1`. |
| ServerRulesOutOfDate | 4 | not G0 | **[O97]** `1` when the copy of the rules on the Exchange server needs updating. It is set when the rules or options change, or when an upload fails for lack of server space, and cleared after a successful upload. When updates are automatic, Outlook uploads at startup if it's set. |
| ServerUpdateMode | 4 | not G0 | **[O97]** The "Update server" option in the Rules Wizard's Options dialog: `1` = Manually (only when the user clicks "Update Now"), `2` = Automatically. `0` = not set, as written by Outlook 2010+. Switching from Manually to Automatically triggers an immediate upload. |
| PromptToConvertInboxAssistantRules | 4 | not G0 | **[O97]** The "Prompt to convert Inbox Assistant rules" option: `1` = ask whether to convert the old Exchange Inbox Assistant rules found on the server. Cleared by "Do not prompt me again". Always `1` observed. |
| ConvertInboxAssistantRules | 4 | not G0 | **[O97]** The last answer to that prompt: `1` = Yes (convert), `0` = No. Always `1` observed, but `0` is valid. Readers MUST accept both. |
| Unknown9 | 4 | G2 | Always `0` observed. |
| NumberOfRules | 2 | all | Number of Rule structures that follow. |

The header is 38 bytes in G0s and G1, 46 bytes in G2, and 2 bytes in G0.

Observed WriterVersion values:

| Writer | Target (Signature) | WriterVersion |
|---|---|---|
| Outlook 2007 | 1200000 or 1000000 | `0x05124F80` (index 5, stamp 1200000) |
| Outlook 2007 (one file, `FormsException.rwz`) | 1000000 | `0x03124F80` (index 3) |
| Outlook 2010+ | 0x140000 or 1000000 | `0x06140000` (index 6, stamp 0x140000) |
| Outlook 2010+ (`New732.rwz`) | 1000000 | `0x03140000` (index 3) |
| Outlook 2010+ (`Outlook2003All.rwz`) | 1100000 | `0x04140000` (index 4) |

**[O2000]** Outlook 2000 reads and writes these fields in the same order. A new profile starts with Unknown1–4 = `0`, ServerRulesOutOfDate = `0`, ServerUpdateMode = `2` (Automatically) and both Inbox Assistant fields = `1`.

Unknown4, ServerRulesOutOfDate and ServerUpdateMode depend on the writer, not the target format:

| Writer | (Unknown4, ServerRulesOutOfDate, ServerUpdateMode) |
|---|---|
| Outlook 98 / 2000 | (0, 1, 2) |
| Outlook 2003 / 2007 | (1, 0, 0) |
| Outlook 2010+ | (0, 0, 0) |

### 4.3 Rule

```
Rule := RuleHeader  Element[RuleHeader.NumberOfElements]
```

#### 4.3.1 RuleHeader

| Field | Size | Generations | Description |
|---|---|---|---|
| Signature | 4 | G2 | A version stamp. Always equal to RulesHeader.Signature. |
| Name | variable | all | String (String8 in G0, G0s and G1; StringW in G2). Outlook limits rule names to 255 characters. **[O97]** Outlook 97 writes `<rule name>` TAB `<template name>`, where the template is the wizard template the rule was made from, for example `Forward within 20 days\tBuild as I go`. Every Outlook 97 sample has the tab; samples from later versions sometimes do. **[O2000]** Outlook 2000 splits the name at the first tab when loading and saves only the part before it, so it drops the template name. |
| Enabled | 4 | all | `1` = enabled, `0` = disabled. Readers SHOULD treat any non-zero value as enabled. New rules default to enabled **[O97]**. |
| Unknown1 | 4 | all | **[O2000]** Run error: `1` after the rule failed while Outlook was running it on the client. When an action of a client rule fails, Outlook 2000 sets this field to `1`, turns the rule off (Enabled = `0`) and shows an error message naming the rule. A rule that runs without error gets `0`. **[O97]** New rules get `0`; Outlook 97 copies and saves it but never reads it. Always `0` observed. |
| ServerRule | 4 | all | **[O97]** Set to `1` once the rule has been saved to the Exchange server's rules table (Outlook 97 serializes the rule and writes `PR_RULE_PROVIDER_DATA`, `PR_RULE_STATE` and the other server-rule properties through MAPI). Cleared again if saving fails or the server rules are reset. Usually `0`; `1` in 3 rules written by Outlook 2010+. |
| Unknown3 | 4 | G1, G2 | Rule flags. Added in version 970812: Outlook 98 reads and writes it only for streams of that version or later, which is why Outlook 97 exports don't have it **[O98]**. Outlook copies it to and from offset `0x18` of the rule's Exchange server rule (`PR_RULE_PROVIDER_DATA`) **[O98]**. Outlook 98 and 2000 clear it to `0` when the user edits a rule that has bit `0x1` or `0x2` set, so those bits **[Inferred]** mark errors that editing fixes **[O98]** **[O2000]**. The other bits mark rules that Outlook 2000 creates itself and later finds again by their flag ([§4.3.1.1](#4311-rule-flags)). `0` for rules the user creates. |
| Unknown4 | 4 | G2 | **[Unknown]** `0`, `1` or `2`. Non-zero exactly when ServerRule is `1`, so probably more server-rule state. |
| DataSize | 4 | G2 | Number of bytes from the end of this field to the end of the rule: NumberOfElements, every object tag, and every element. Matched exactly in all 116 G2 rules. |
| NumberOfElements | 2 (or 6) | all | Number of elements in this rule. **[O97]** Written by `CObList::Serialize` with `CArchive::WriteCount`: a `u16`, or `0xFFFF` followed by a `u32` if the count is 65535 or more. |

##### 4.3.1.1 Rule flags

**[O2000]** Outlook 2000 creates some rules itself and sets their flags: three junk-mail rules from a built-in table, and the Download Options rule. It then looks for them by flag, not by name, which is why a renamed rule is still recognised. Copying a rule in the Rules Wizard clears all flags on the copy:

| Bit | Rule | Elements Outlook 2000 creates |
|---|---|---|
| `0x01`, `0x02` | **[Unknown]** | Outlook 98 and 2000 never set these bits. They only clear all the flags when the user edits a rule with either bit set, and carry the bits unchanged to and from the server copy of the rule. So another writer sets them, probably a later Outlook or an Exchange client. |
| `0x08` | Junk e-mail rule | Condition `0x00EB` (junk senders), action `0x012C` (move to folder). |
| `0x10` | Adult content rule | Condition `0x00EC` (adult content senders), action `0x012C`. |
| `0x20` | "Exception List" rule | Condition `0x00E9` (senders on my Exception List), action `0x0143` (don't search for commercial or adult content). |
| `0x40` | The large-message rule of the "Download Options" dialog ("Don't download messages larger than *n* KB", with exceptions for chosen senders, high importance and a flag, and a "Restore Default Rule" button) | Condition `0x00E0` (size), actions `0x0130` and `0x012C`, exceptions `0x01F7`, `0x01FE` and `0x01FC`. |

The sample `ExceptionList/Outlook2000_ExceptionList_*.rwz` holds the `0x20` rule as Outlook 2000 creates it.

When Outlook 2000 reads a rule back from the Exchange server, it copies Flags from offset `0x18` of `PR_RULE_PROVIDER_DATA` ([Appendix E](#appendix-e-findings-from-outlook-98)). The rule's MAPI state also maps onto elements: `ST_ENABLED` becomes Enabled, and `ST_EXIT_LEVEL` adds the action `0x0142` (stop processing more rules).

#### 4.3.2 Element

| Field | Size | Description |
|---|---|---|
| ObjectTag | 2 (+ class descriptor) | See [§2.5](#25-object-tag). |
| Identifier | 4 | Element identifier ([§5](#5-element-identifiers)). |
| NumberOfParameters | 4 | Number of parameter structures that follow. **[O97]** Outlook 97 writes `1` if the element has a parameter object and `0` if not, and reads any non-zero value as "has a parameter". Outlook 98 does the same, and its word parameter holds a single string **[O98]**. **Outlook 2000 reads the field as a count** and reads that many parameters **[O2000]**. It writes the number of parameters, except that at version 970812 exactly it writes at most `1` and only the first parameter ([§4.1.2](#412-how-outlook-2000-chooses-the-stamp)). Files that store several words as several parameters, as Outlook 2007 does even when exporting "for Outlook 98", therefore need Outlook 2000 or later **[Inferred]**. |
| Parameters | variable | NumberOfParameters parameters. Their layout depends on Identifier ([§6](#6-parameters)). |

Parameter counts:

* "Simple" elements, such as "sent only to me" and "delete it", have **0** parameters.
* Most elements have **1** parameter.
* Word-list elements ([§6.3](#63-wordparameter)) have **one parameter per word or phrase**. The condition matches if any of them matches.
* A simple element with a non-zero count is invalid.

**[O2000]** An identifier that isn't in Outlook 2000's tables makes the whole load fail, except `0x00EA`, which is read as `0x00EB`. A reader can't skip an unknown element on its own, because the parameter layout is unknown; in G2 it can skip the whole rule using DataSize.

#### 4.3.3 Element order

Every rule observed starts with:

1. `0x0190` — the message-type element ([§6.1](#61-eventparameter)), and
2. `0x0064` — "for each *item type*" ([§6.2](#62-itemtypeparameter)).

These are followed by conditions, then actions, then exceptions, in the order the user added them. Readers SHOULD NOT depend on this order. Writers MUST emit `0x0190` and `0x0064` first.

### 4.4 RulesFooter

| Field | Size | Description |
|---|---|---|
| TemplateDirectoryLength | 4 | Number of characters in TemplateDirectory. Outlook keeps it ≤ 260 (`MAX_PATH`). |
| TemplateDirectory | variable | The directory used most recently in the "reply using template" browse dialog, for example `C:\Users\<user>\AppData\Roaming\Microsoft\Templates`. ANSI bytes in G0s and G1; UTF-16 code units in G2. No length prefix (unlike [§2.2](#22-string)) and no NUL terminator. Often empty. **[O97]** Outlook 97 reads at most 259 bytes into a 260-byte buffer, so writers MUST keep it under 260 characters. **[O2000]** Outlook 2000 reads at most 260 bytes; if the length is larger, it doesn't skip the rest, and the following fields are read from the wrong place. |
| Timestamp | 12 | An OleDateTime ([§2.4](#24-oledatetime)). **[O97]** When the Rules Wizard window saves, it supplies this timestamp; other saves write the stored value again. **[Inferred]** The time the rules were last changed. `RULESWIZ.DLL` has the message "Your client rules have been modified more recently than your Exchange Server rules", but no code uses it, so Outlook 97 never compares this timestamp. See notes. |
| Unknown | 4 | MUST be `0` (all 291 footers). **[O97]** **[O2000]** Loaded and saved unchanged; nothing else reads or writes it. |

**[O97]** Outlook 97's loader reads each footer field only if the stream's version is new enough: TemplateDirectory from 960723, Timestamp from 960820, and Unknown from 960925 ([§4.1](#41-version-stamps)). Every stream with a signature is newer than that, so all three are always present.

Timestamp notes:

* Status is null in 231 of 291 samples.
* A valid timestamp of `-109205.0` is 1601-01-01 00:00, the `FILETIME` epoch. It is a zero `FILETIME` converted to an OLE date, and means "never saved".
* Several Outlook 2000 samples hold `-649728.2264`, about the year 120 AD. This is presumably garbage: an uninitialised value or a conversion bug.

---

## 5. Element identifiers

Identifiers are grouped by range:

| Range | Group |
|---|---|
| `0x0064`, `0x0190` | Mandatory |
| `0x00C8`–`0x012B` (200–299) | Conditions |
| `0x012C`–`0x018F` (300–399) | Actions |
| `0x01F4`–`0x0257` (500–599) | Exceptions |

Outlook 97 knew only `0x0064`, conditions `0x00C8`–`0x00E6`, actions `0x012C`–`0x0140`, `0x0190`, and exceptions `0x01F4`–`0x0212` **[O97]**. Outlook 98 extends these to conditions `0x00C8`–`0x00EC`, actions `0x012C`–`0x0143` and exceptions `0x01F4`–`0x0213` **[O98]**. Outlook 97's element table is in [Appendix D](#appendix-d-findings-from-ruleswizdll) and Outlook 98's in [Appendix E](#appendix-e-findings-from-outlook-98). For conditions `0x00C8`–`0x00E6`, the matching exception is the condition's identifier + 300 (`0x012C`). After that the exception numbers are assigned in sequence and the +300 relationship breaks: `0x00E8` → `0x0213`, `0x00EE` → `0x0214`, `0x00F0` → `0x0215`, and so on.

The "Param" column refers to [§6](#6-parameters). "—" means the element has no parameters. "Client" marks elements that make a rule client-only, according to `docs/Rules Sever Side.xlsx`.

### 5.1 Mandatory

| ID | Meaning | Param |
|---|---|---|
| `0x0064` | "For each *message*": which kinds of item the rule applies to **[O97]**. | §6.2 |
| `0x0190` | "Apply this rule *after the message arrives*": when the rule runs **[O97]**. | §6.1 |

### 5.2 Conditions

| ID | UI text | Param | Client | Notes |
|---|---|---|---|---|
| `0x00C8` | where my name is in the To box ("sent directly to me" in Outlook 97) | — | | |
| `0x00C9` | sent only to me | — | | |
| `0x00CA` | where my name is not in the To box | — | | |
| `0x00CB` | from *people or public group* | §6.4 | | |
| `0x00CC` | sent to *people or public group* | §6.4 | | |
| `0x00CD` | with *specific words* in the subject | §6.3 | | |
| `0x00CE` | with *specific words* in the body | §6.3 | | |
| `0x00CF` | with *specific words* in the subject or body | §6.3 | | |
| `0x00D0` | flagged for *action* | §6.5 | | |
| `0x00D2` | marked as *importance* | §6.6 | | |
| `0x00D3` | marked as *sensitivity* | §6.7 | | |
| `0x00D4` | where my name is in the To box and it is a meeting | — | | Never created by the Rules Wizard; supported by Outlook 97's evaluator ([Appendix D.4](#d4-the-rule-evaluator)). |
| `0x00D5` | where my name is not in the To box and it is a meeting | — | | As `0x00D4`. |
| `0x00D7` | assigned to *category* category | §6.8 | ✓ | |
| `0x00DA` | sent to *people or public group* as Cc | §6.4 | | As `0x00D4`. **[Inferred]** parameter, from the evaluator reading the element's address list. |
| `0x00DB` | sent to *people or public group* | §6.4 | | As `0x00DA`, but the same test as `0x00CC`. |
| `0x00DC` | which is an automatic reply / Out of Office message | — | | |
| `0x00DE` | which has an attachment | — | | |
| `0x00DF` | with *selected properties* of documents or forms | §6.9 | ✓ | |
| `0x00E0` | with a size *in a specific range* | §6.10 | | |
| `0x00E1` | received *in a specific date span* | §6.11 | | |
| `0x00E2` | where my name is in the Cc box | — | | |
| `0x00E3` | where my name is in the To or Cc box | — | | |
| `0x00E4` | uses the *form name* form | §6.12 | | Not functional in Outlook 2019. |
| `0x00E5` | with *specific words* in the recipient's address | §6.3 | ✓ | |
| `0x00E6` | with *specific words* in the sender's address | §6.3 | | |
| `0x00E7` | *none* (Net Folders) | — | | Only seen in the hidden `#NET FOLDERS#` rule created by Outlook 98/2000 Net Folders (`NetFolders/Outlook2000_NetFolders_Default.rwz`). Outlook 98 defines it with no parameter, the text "(none)" and empty masks, so the wizard never offers it **[O98]**. **[O2000]** It means "the subject begins with `#NET FOLDERS#`": Outlook 2000 turns it into a prefix content restriction on `PR_SUBJECT`. Net Folders' own messages carry that subject. |
| `0x00E8` | with *specific words* in the message header | §6.3 | | Added in Outlook 98 **[O98]**. |
| `0x00E9` | from senders on my *Exception List* | §6.13 | ✓ | Junk-mail feature of Outlook 98/2000; removed in 2003. Parameter kind `0x18` **[O98]**. |
| `0x00EA` | *older form of `0x00EB`* | §6.13 | ✓ | Not in Outlook 98's or 2000's tables, but Outlook 2000 reads it as `0x00EB` **[O2000]**. Probably from pre-release Outlook 98 builds. |
| `0x00EB` | suspected to be junk e-mail or from *Junk Senders* | §6.13 | ✓ | Added in Outlook 98, removed in 2003. Parameter kind `0x1A` **[O98]**. |
| `0x00EC` | containing adult content or from *Adult Content Senders* | §6.13 | ✓ | Added in Outlook 98, removed in 2003. Parameter kind `0x1B` **[O98]**. |
| `0x00ED` | with a relevance *in a specific range* | §6.14 | ✓ | Added in Outlook 2000 **[O2000]**. Hidden unless `HKCU\Software\Microsoft\Office\8.0\Outlook\Relevance` exists. |
| `0x00EE` | through the *specified* account | §6.15 | ✓ | Added in Outlook 2000 **[O2000]**. Later versions require `0x00EF`, which is newer than Outlook 2000. |
| `0x00EF` | on this computer only ("on this machine only" in 2003/2007) | §6.16 | ✓ | |
| `0x00F0` | sender is in *specified* Address Book | §6.17 | ✓ | Requires `0x00EF`. |
| `0x00F1` | which is a meeting invitation or update | — | | |
| `0x00F3` | which is an *Alert E-mail* | §6.18 | | Created only from an Office alert source. |
| `0x00F4` | of the *specific* form type (InfoPath) | §6.12 | ✓ | Requires InfoPath. |
| `0x00F5` | from RSS feeds with *specified text* in the title | §6.3 | | |
| `0x00F6` | assigned to any category | — | | |
| `0x00F7` | from any RSS feed | — | | |

### 5.3 Actions

| ID | UI text | Param | Client | Notes |
|---|---|---|---|---|
| `0x012C` | move it to the *specified* folder | §6.19 | | |
| `0x012D` | delete it | — | | |
| `0x012E` | forward it to *people or public group* | §6.4 | | |
| `0x012F` | reply using *a specific template* | §6.20 | ✓ | Path to an `.oft` file. |
| `0x0130` | display *a specific message* in the New Item Alert window ("notify me using …" in Outlook 98) | §6.20 | ✓ | |
| `0x0131` | flag message for *action in a number of days* | §6.21 | ✓ | Pre-2007 flag. |
| `0x0132` | clear the Message flag | — | ✓ | |
| `0x0133` | assign it to the *category* category | §6.8 | ✓ | |
| `0x0136` | play *a sound* | §6.20 | ✓ | |
| `0x0137` | mark it as *importance* | §6.6 | ✓ | |
| `0x0138` | mark it as *sensitivity* | §6.7 | ✓ | |
| `0x0139` | move a copy to the *specified* folder | §6.19 | | |
| `0x013A` | notify me when it is read | — | ✓ | Sent-mail rules. |
| `0x013B` | notify me when it is delivered | — | ✓ | Sent-mail rules. |
| `0x013C` | Cc the message to *people or public group* | §6.4 | | Sent-mail rules. |
| `0x013E` | defer delivery by *a number of* minutes | §6.22 | ✓ | Sent-mail rules. |
| `0x013F` | perform *a custom action* | §6.23 | ✓ | Removed in Outlook 2010. |
| `0x0140` | *none* | — | | **[O97]** Defined by Outlook 97 with no UI text, no parameter and every flag clear: a hidden or retired action. |
| `0x0141` | *none* (Net Folders) | — | ✓ | Only seen in the hidden `#NET FOLDERS#` rule, with `0x00E7`. Defined by Outlook 98 as client-only, with empty masks **[O98]**. **[O2000]** It hands the message to Net Folders: Outlook 2000 moves it into a folder whose entry ID is kept in property `0x60010102`, schedules Net Folders to process it, and stops processing more rules. |
| `0x0142` | stop processing more rules | — | | Added in Outlook 98 **[O98]**. When Outlook 98 imports an Exchange server rule that has `ST_EXIT_LEVEL` set, it adds this action. |
| `0x0143` | do not search message for commercial or adult content | — | ✓ | Added in Outlook 98 with empty masks, so only the junk-mail feature creates it **[O98]**. Removed in 2003. |
| `0x0144` | redirect it to *people or public group* | §6.4 | | Added in Outlook 2000 **[O2000]**. |
| `0x0145` | add *number* to relevance | §6.24 | ✓ | Added in Outlook 2000 **[O2000]**. Hidden; see `0x00ED`. |
| `0x0146` | have server reply using *a specific message* | §6.25 | | Added in Outlook 2000 **[O2000]**. |
| `0x0147` | forward it to *people or public group* as an attachment | §6.4 | | Added in Outlook 2000 **[O2000]**. |
| `0x0148` | print it | — | ✓ | Added in Outlook 2000 **[O2000]**. |
| `0x0149` | start *application* | §6.20 | ✓ | Added in Outlook 2000 **[O2000]**. Hidden in Outlook 2016+. |
| `0x014A` | permanently delete it | — | ✓ | Added in Outlook 2000 **[O2000]**. Outlook also requires `0x0142`. |
| `0x014B` | run *a script* | §6.26 | ✓ | Hidden in Outlook 2016+. |
| `0x014C` | mark it as read | — | ✓ | |
| `0x014D`, `0x014E` | *unknown* | ? | | Seen only in Outlook binaries. |
| `0x014F` | display a Desktop Alert | — | ✓ | |
| `0x0150` | *flag color* (`RuleElementFlagColorAction`) | ? | ✓ | Seen only in Outlook binaries. |
| `0x0151` | flag message for *follow up at this time* | §6.27 | ✓ | |
| `0x0152` | clear message's categories | — | | |
| `0x0153` | apply retention policy: *retention policy* | §6.28 | | |

### 5.4 Exceptions

Every exception has the same parameter layout as its condition.

| ID | Condition | ID | Condition |
|---|---|---|---|
| `0x01F4` | `0x00C8` | `0x020B` | `0x00DF` |
| `0x01F5` | `0x00C9` | `0x020C` | `0x00E0` |
| `0x01F6` | `0x00CA` | `0x020D` | `0x00E1` |
| `0x01F7` | `0x00CB` | `0x020E` | `0x00E2` |
| `0x01F8` | `0x00CC` | `0x020F` | `0x00E3` |
| `0x01F9` | `0x00CD` | `0x0210` | `0x00E4` |
| `0x01FA` | `0x00CE` | `0x0211` | `0x00E5` |
| `0x01FB` | `0x00CF` | `0x0212` | `0x00E6` |
| `0x01FC` | `0x00D0` | `0x0213` | `0x00E8` |
| `0x01FE` | `0x00D2` | `0x0214` | `0x00EE` |
| `0x01FF` | `0x00D3` | `0x0215` | `0x00F0` |
| `0x0203` | `0x00D7` | `0x0216` | `0x00F1` |
| `0x0208` | `0x00DC` | `0x0218` | `0x00F4` |
| `0x020A` | `0x00DE` | `0x0219` | `0x00F5` |
| | | `0x021A` | `0x00F6` |
| | | `0x021B` | `0x00F7` |

### 5.5 Downgrading

When Outlook exports to an older format, it omits every rule that contains an element the older format cannot represent. Rules are dropped whole, never partially. For example, `Outlook2007_RunScript_98.rwz`, `…_FlagForFollowUp_2000.rwz` and `…_DisplayDesktopAlert_98.rwz` all contain zero rules.

As a result, parameters that only exist in G2 always use StringW, even where this document's tables say "String".

---

## 6. Parameters

MFC class names in the headings below are matched to parameters by name only, from strings in Outlook's binaries **[Inferred]**.

Every parameter starts with a 4-byte **Reserved** field. It MUST be `0` (all 791 parameters observed). **[O97]** It is a field of the common parameter base class. The constructor sets it to `0`, the base `Serialize` writes it first, and the class has a virtual getter and setter for it. Nothing in Outlook 97 calls them, and no parameter class reads or writes the field directly: it is reserved.

The tables below list the fields after Reserved.

### 6.1 EventParameter
Used by `0x0190`.

| Field | Size | Description |
|---|---|---|
| Flags | 4 | When the rule runs. A bitmask; the UI joins set bits with " or ". `0x01` = after the message arrives, `0x04` = after I send the message, `0x08` = after the server receives the message **[O97]**. |

Observed values: `0x01` (272 rules) and `0x04` (6 rules).

### 6.2 ItemTypeParameter
Used by `0x0064` ("For each %s"). `ItemTypeParameter` in the library; `Rule.itemTypes` holds its value.

| Field | Size | Description |
|---|---|---|
| ItemTypes | 4 | **[O97]** A bitmask of the kinds of item the rule applies to, shown joined with " or ". Outlook 97 defines only `0x1` = "message", which is also the constructor's default. Its rule evaluator treats this element as always matching. Always `1` (278 of 278). |

### 6.3 WordParameter
`CWordParameter`. Used by `0x00CD`–`0x00CF`, `0x00E5`, `0x00E6`, `0x00E8`, `0x00F5` and their exceptions.

| Field | Size | Description |
|---|---|---|
| Value | variable | String. One word or phrase. |

An element has one WordParameter per word or phrase. The words are combined with OR. They are not delimited inside one string.

Outlook 97 and 98 allow only **one phrase per condition** **[O97]** **[O98]**:

* the prompt is "Specify a word or phrase to search for…", typed into a single text box (the "Parameter Text" dialog);
* the element reads at most one parameter;
* Outlook 97 matches the whole phrase as a substring of the subject or body, ignoring case.

Several words per condition, stored as several parameters, came with Outlook 2000 **[O2000]**.

### 6.4 AddressParameter
Used by `0x00CB`, `0x00CC`, `0x012E`, `0x013C`, `0x0144`, `0x0147`, `0x01F7` and `0x01F8`.

This is a serialized MAPI `ADRLIST` **[O97]**. For each `ADRENTRY`, Outlook 97 writes `ulReserved1` and `cValues`, copies the property array into one block (MAPI `ScCopyProps`), relocates its pointers to offsets from 0 (`ScRelocProps`), and writes the block's size and bytes. The uninitialised bytes inside `SPropValue`s are copied as they were in memory.

| Field | Size | Description |
|---|---|---|
| NumberOfEntries | 4 | `ADRLIST.cEntries`. |
| Entries | variable | NumberOfEntries × AdrEntry. |
| MatchAny | 4 | **[O97]** How the names are combined in the rule text: non-zero = " or ", `0` = " and ". Outlook 97 sets `1` for the conditions and exceptions (`0x00CB`, `0x00CC`, `0x01F7`, `0x01F8`) and `0` for the actions. All samples agree: 14 conditions with `1`, 11 actions with `0`. |
| IsCc | 4 | **[O97]** Set to `1` only for the "Cc the message to" action (`0x013C`); `0` otherwise. Outlook 97 never reads it: the Cc action always sets `PR_RECIPIENT_TYPE` to `MAPI_CC` itself. |

**AdrEntry**

| Field | Size | Description |
|---|---|---|
| Reserved1 | 4 | `ADRENTRY.ulReserved1`. Values vary and are often uninitialised memory; some are property tags such as `0x0FFF0102`. Readers MUST ignore it. Writers SHOULD write `0`. |
| NumberOfValues | 4 | `ADRENTRY.cValues`. |
| BlockSize | 4 | Size in bytes of the block that follows: the PropValue array plus the data area. |
| PropValues | 16 × NumberOfValues | SPropValue records. |
| Data | variable | Strings and binary values referenced by offsets. Offsets are measured from the first byte of PropValues. |

**[O2000]** Outlook 2000 writes an entry with no values as BlockSize `0` and no block, and an empty address list as NumberOfEntries `0`. When showing the rule, it lists at most 10 names, and takes each name from a `PT_STRING8` PR_DISPLAY_NAME.

**SPropValue (16 bytes)**

| Field | Size | Description |
|---|---|---|
| PropTag | 4 | A property tag: the type in the low 16 bits and the ID in the high 16 bits ([MS-OXCDATA] §2.9). |
| AlignPad | 4 | `dwAlignPad`. Uninitialised memory. MUST be ignored and SHOULD be preserved when round-tripping. |
| Value | 8 | `union _PV`. Its encoding depends on the property type (below). |

| Type | Value encoding |
|---|---|
| `PT_LONG` (`0x0003`), `PT_ERROR` (`0x000A`) | `u32` in bytes 0–3. Bytes 4–7 are uninitialised. |
| `PT_BOOLEAN` (`0x000B`) | **[Inferred]** `u16` in bytes 0–1; the rest is uninitialised. Supported by the library but never observed. |
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

### 6.5 FlaggedForActionParameter
Used by `0x00D0` and `0x01FC`. **[O97]** This is the same class as FlagParameter ([§6.21](#621-flagparameter)), with IsCondition set.

| Field | Size | Description |
|---|---|---|
| Days | 4 | Unused by conditions. Always `0`. |
| Action | variable | String. Localised flag text, for example `Follow up`, `Forward`, `Do not Forward`, or `Any`. "Any" is only offered when IsCondition is set **[O97]**. |
| IsCondition | 4 | `1` **[O97]**: the factory sets it for these elements. It switches the text from "*action* within *n* days" to just "*action*". |

### 6.6 ImportanceParameter
`CImportanceDialog`. Used by `0x00D2`, `0x0137` and `0x01FE`.

| Field | Size | Description |
|---|---|---|
| Importance | 4 | PR_IMPORTANCE value: `0` = low, `1` = normal, `2` = high. |

### 6.7 SensitivityParameter
`CSensitivityDialog`. Used by `0x00D3`, `0x0138` and `0x01FF`.

| Field | Size | Description |
|---|---|---|
| Sensitivity | 4 | PR_SENSITIVITY value: `0` = normal, `1` = personal, `2` = private, `3` = confidential. |

### 6.8 CategoryParameter
`CCategoryParameter`. Used by `0x00D7`, `0x0133` and `0x0203`.

| Field | Size | Description |
|---|---|---|
| Categories | variable | String. Category names separated by `;`. |

### 6.9 FormParameter
`CFormParameter`. Used by `0x00DF` and `0x020B`.

| Field | Size | Description |
|---|---|---|
| Forms | variable | String. Form display names separated by `;`. |
| NumberOfProperties | 2 (or 6) | Number of DocumentProperty records that follow. **[O97]** Written by MFC `CArray::Serialize` with `CArchive::WriteCount` (`u16`, or `0xFFFF` + `u32`), which is why it is narrower than NumberOfClasses. |
| Properties | variable | DocumentProperty records. |
| NumberOfClasses | 4 | Number of message classes that follow. This count is a `u32`. |
| Classes | variable | String8 (ANSI in every generation). Message classes, for example `IPM.Appointment`. |

**DocumentProperty**

| Field | Size | Description |
|---|---|---|
| Field | variable | String. Display name of the property, for example `Author`. Outlook limits it to 32 characters. |
| PropTag | 4 | A property tag. Observed IDs are named-property IDs (≥ `0x8000`, for example `0x81A2001F` and `0x8308001F`), which are **mapped per store**. The ID is not portable between stores; Field identifies the property. |
| StringMatch | 4 | `0` = contains, `1` = is exactly, `2` = does not contain. |
| StringValue | variable | String. |
| NumberMatch | 4 | `0` = equals, `1` = not equal to, `2` = at most, `3` = at least, `4` = more than, `5` = less than. |
| NumberValue1 | 4 | `i32`. Compared with 16-bit (`PT_I2`) properties **[O97]**. |
| NumberValue2 | 4 | `i32`. Compared with 32-bit (`PT_LONG`) properties **[O97]**. |
| BoolMatch | 4 | `0` = yes / true, `1` = no / false. |
| Unknown1 | 4 | **[Unknown]** Always `1`. **[O97]** Every constructor sets it to `1`; the matching code never reads it, and the Document or Form Properties dialog never changes it. Outlook 2000 is the same **[O2000]**. |
| DateMatch | 4 | `0` = before, `1` = after. |
| DateValue | 12 | OleDateTime. Defaults to the current time **[O97]**. |
| MatchIfMissing | 4 | **[O97]** Non-zero: a message without this property counts as a match; `0`: it does not. Only present when the stream's version is 970102 or later, which is every stream that can be identified. Every constructor sets it to `0`, and the dialog has no control for it, so Outlook 97 never creates a non-zero value. Its matcher does honour one. **[O2000]** Outlook 2000 never sets it either. Its Document Properties dialog keeps a non-zero value when it saves the list again, and adds a copy of that property with the tag of the property's other name (for example `Subject` and `Document Subject`) and MatchIfMissing `0`. Always `0` observed. |

The property type in PropTag selects which match/value pair applies: strings use StringMatch, integers NumberMatch, booleans BoolMatch and `PT_SYSTIME` DateMatch. The unused fields are written as zero or null.

### 6.10 SizeParameter
`CSizeParameter`. Used by `0x00E0` and `0x020C`.

| Field | Size | Description |
|---|---|---|
| Minimum | 4 | Minimum size in KB. |
| Maximum | 4 | Maximum size in KB. |

### 6.11 TimeParameter
`CTimeParameter`. Used by `0x00E1` and `0x020D`.

| Field | Size | Description |
|---|---|---|
| HasAfter | 4 | Non-zero if the "after" bound applies. |
| After | 12 | OleDateTime. |
| HasBefore | 4 | Non-zero if the "before" bound applies. |
| Before | 12 | OleDateTime. |

### 6.12 FormTypeParameter
Used by `0x00E4`, `0x0210`, `0x00F4` (`CInfoPathFormTypeParameter`) and `0x0218`.

| Field | Size | Description |
|---|---|---|
| Name | variable | String. Form display name. |
| MessageClass | variable | String8 (ANSI in every generation). For example `IPM.Contact` or `IPM.InfoPathForm.<id>$<id>`. |

### 6.13 SendersListParameter
Used by `0x00E9`, `0x00EB` and `0x00EC`. These elements exist only in G1.

| Field | Size | Description |
|---|---|---|
| Name | variable | String8. Observed values: `Exception List`, `Junk Senders` and `Adult Content Senders`. |

### 6.14 RelevanceRangeParameter
Used by `0x00ED`.

| Field | Size | Description |
|---|---|---|
| Minimum | 4 | |
| Maximum | 4 | |

### 6.15 AccountParameter
`CAccountParameter`. Used by `0x00EE` and `0x0214`, from Outlook 2000.

| Field | Size | Description |
|---|---|---|
| AccountName | variable | String: ANSI in the Outlook 2000 format **[O2000]**, UTF-16 in G2. |
| AccountStamp | variable | String8. **[Inferred]** An account identifier formatted as a signed decimal `i32`, for example `1285009305` or `-458008816`. |

### 6.16 ProfileStampParameter
Used by `0x00EF`.

| Field | Size | Description |
|---|---|---|
| Stamp | 16 | GUID. **[Inferred]** Identifies the profile or machine that "this computer" refers to. Files exported from the same machine carry the same GUID. |

### 6.17 AddressBookParameter
`CABContListDialog`. Used by `0x00F0` and `0x0215`.

| Field | Size | Description |
|---|---|---|
| EntryID | variable | Counted entry ID ([§2.3](#23-counted-entry-id)) of the address book container. |
| Name | variable | StringW. |

### 6.18 AlertParameter
Used by `0x00F3`.

| Field | Size | Description |
|---|---|---|
| Name | variable | StringW. The alert's name. |

### 6.19 FolderParameter
`CFolderParameter`. Used by `0x012C` and `0x0139`.

| Field | Size | Description |
|---|---|---|
| FolderEntryID | variable | Counted entry ID of the target folder. |
| StoreEntryID | variable | Counted entry ID of the store that holds the folder. |
| FolderName | variable | String. Display name. |
| SecondaryStore | 4 | Added in version 970718 **[O98]**, so it is absent in Outlook 97's formats (G0 and signature 970102). **[Unknown]** Named "secondary user store" by the library. Always `1` observed. |

### 6.20 PathParameter / MessageParameter
`CLaunchFileParameter`, `CMessageParameter` and `CTemplateParameter`. Used by `0x012F` (template path), `0x0130` (alert message text), `0x0136` (sound file) and `0x0149` (application path).

| Field | Size | Description |
|---|---|---|
| Value | variable | String. |

### 6.21 FlagParameter
Used by `0x0131`.

| Field | Size | Description |
|---|---|---|
| Days | 4 | Due in this many days. Shown as "*action* within *days* days". |
| Action | variable | String. Flag text. |
| IsCondition | 4 | `0` for this action **[O97]**. See [§6.5](#65-flaggedforactionparameter). |

### 6.22 DeferParameter
`CDeferDialog`. Used by `0x013E`.

| Field | Size | Description |
|---|---|---|
| Minutes | 4 | |

### 6.23 CustomActionParameter
Used by `0x013F`.

| Field | Size | Description |
|---|---|---|
| Location | variable | String. The DLL implementing the action. |
| Name | variable | String. |
| Options | variable | String. |
| Value | variable | String. |

### 6.24 RelevanceParameter
`CRelevanceParameter`. Used by `0x0145`.

| Field | Size | Description |
|---|---|---|
| Value | 4 | The number to add to the relevance. |

### 6.25 ServerReplyParameter
`CReplyServerParameter`. Used by `0x0146`.

| Field | Size | Description |
|---|---|---|
| MessageEntryID | variable | Counted entry ID of the reply template message, which is stored in the mailbox. |
| Name | variable | String: ANSI in the Outlook 2000 format **[O2000]**, UTF-16 in G2. |

### 6.26 ScriptParameter
Used by `0x014B`.

| Field | Size | Description |
|---|---|---|
| Name | variable | StringW. **[Unknown]** Presumably the VBA project/module name. |
| Function | variable | StringW. |

### 6.27 FlagForFollowUpParameter
`ToDoActionDlg`. Used by `0x0151`.

| Field | Size | Description |
|---|---|---|
| FollowUp | 4 | `1` = today, `2` = tomorrow, `3` = this week, `4` = next week, `7` = no date, `10` = complete. |
| Action | variable | StringW. Flag text. |

### 6.28 RetentionPolicyParameter
Used by `0x0153`.

| Field | Size | Description |
|---|---|---|
| PolicyId | 16 | GUID of the retention tag. |
| Name | variable | StringW. |

---

## 7. Writing

To produce a stream that Outlook accepts:

1. Choose a generation and Signature. Unless backward compatibility is needed, write G2 with Signature `0x00140000` and WriterVersion `0x06140000`.
2. Header Unknown1–4 = `0`, ServerRulesOutOfDate = `0`, ServerUpdateMode = `0`, PromptToConvertInboxAssistantRules = `1`, ConvertInboxAssistantRules = `1`, Unknown9 = `0`.
3. For each rule, write RuleHeader.Signature = the stream's Signature, and compute DataSize as defined in [§4.3.1](#431-ruleheader).
4. Write `CRuleElement`'s class descriptor before the stream's first element, and `0x8001` before every other element.
5. Every rule MUST begin with elements `0x0190` and `0x0064`.
6. Write all Reserved fields as `0`. Write SPropValue.AlignPad and AdrEntry.Reserved1 as `0`, or preserve the original values.
7. Write the footer with Status = null (`2`) and Date = `0.0` unless a real timestamp is known.

## Appendix A. Worked example

The smallest G2 stream: one enabled rule named `RULENAME`, applied "after the message arrives", written by this library (`ExportTests.testEmptyRule`):

```
00 00 14 00                         Signature           0x00140000 (v14)
00 00 14 06                         WriterVersion       index 6, stamp 0x140000
00 00 00 00 ×3                      Unknown1-3
00 00 00 00  00 00 00 00  00 00 00 00   Unknown4-6
01 00 00 00                         Unknown7
01 00 00 00                         Unknown8
00 00 00 00                         Unknown9
01 00                               NumberOfRules = 1
  00 00 14 00                       Rule.Signature
  08 52 00 55 00 … 45 00            Name = StringW "RULENAME"
  01 00 00 00                       Enabled
  00 00 00 00 ×4                    Unknown1-4
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

## Appendix B. Open questions

1. RulesHeader Unknown1–4 and the footer's Unknown, which Outlook 97, 98 and 2000 only preserve. Outlook 2003/2007 set Unknown4 to `1`.
2. The high byte of RulesHeader.WriterVersion.
3. RuleHeader Unknown4 (G2 only, non-zero only on server rules).
4. Whether versions after Outlook 2000 give the parameter Reserved field a meaning, or ever write a non-zero DocumentProperty MatchIfMissing.
5. Which product writes G0s (Signature 0) streams, and how `PidTagRwRulesStream` differs from an exported `.rwz`.
6. DocumentProperty Unknown1: always `1`, and never read by Outlook 97, 98 or 2000.
7. Layouts of `0x014D`, `0x014E` and `0x0150`, and whether stamp 0x150000 changes the layout.
8. Rule Flags bits `0x1`/`0x2`. Outlook 97, 98 and 2000 never set them.
9. The meaning of the definition flags at `+0x20` and `+0x24`, which Outlook 97, 98 and 2000 never read (Appendix D.1).

## Appendix C. Corrections to earlier notes

* **0x0064 "unknown element".** It is "For each *message*" ([§6.2](#62-itemtypeparameter)).

These items in `docs/RWZ Format.docx` contradict the sample corpus:

* **"Extended" field.** This is NumberOfParameters ([§4.3.2](#432-element)). It can be 2 or more for word lists.
* **"Separator" / "Padding" / "Class Name" in the rule header.** These are the MFC object tag and the class schema of the next element ([§2.5](#25-object-tag)).
* **"Unknown3 MUST NOT be present in Outlook 2000 and earlier."** It is present in G1 (Outlook 98/2000).
* **"Unknown8 always one … Unknown4–6 unknown."** Unknown7 is also always `1`. Unknown4–6 follow the writer ([§4.2](#42-rulesheader)).
* **Fixed property IDs `0x8222`–`0x823A` for document properties.** Observed IDs differ because they are named-property mappings ([§6.9](#69-formparameter)).
* **PropertyValueArray "Unknown, always zero".** It is `ADRENTRY.ulReserved1`, and is usually non-zero garbage.
* **Signature format "major × 100000 + minor/build".** Only true for stamps 1000000–1200000 ([§4.1](#41-version-stamps)).

## Appendix D. Findings from RULESWIZ.DLL

`docs/Internals/RULESWIZ.DLL` is the Outlook 97 Rules Wizard add-in: a 32-bit DLL that statically links MFC. It was disassembled with `objdump`, starting from the MFC runtime-class records for `CRule`, `CRuleElement` and `CRuleComponent` and following their vtables. Code addresses are given so the work can be checked.

| Item | Address |
|---|---|
| `CRuleElement` runtime class (size `0x54`, schema 0) | `0x10084DF0` |
| `CRuleElement::Serialize` | `0x1003B475` |
| `CRule::Serialize` | `0x100334A9` |
| Parameter base `Serialize` (writes Reserved) | `0x10032DC9` |
| Parameter factory (definition kind → class) | `0x100492B6`, jump table `0x1006E2C0` |
| Element definition table, built in code | `0x1000629A`–`0x10008437` |
| Element ID → definition lookup | `0x1004A866` |
| Upload of rules to the Exchange server (sets ServerRule) | `0x10043185`, `0x10035A8D` |

### D.1 Element definitions

Outlook 97 builds one definition object per element. Its fields are:

* `+0x08`: a group letter: `C` for conditions, `A` actions, `X` exceptions, `E` for `0x0190`, `I` for `0x0064`.
* `+0x0C`: the parameter kind.
* `+0x18`: two packed 16-bit values ("Pair").
* `+0x1C`: the client-only flag. It matches the client-only column of `docs/Rules Sever Side.xlsx` for every Outlook 97 element.
* `+0x20`, `+0x24`: two more flags. Outlook 97 sets them in its constructors and copy constructor, but no code reads them: every read of those offsets in `RULESWIZ.DLL` belongs to another class **[O97]**. No reader was found in Outlook 98 or 2000 either. They have no effect on the file format. In Outlook 2000's tables, `+0x24` is `0` for `0x00E3`–`0x00ED`, `0x013E`–`0x0143`, the exceptions `0x020F`–`0x0213` and the exception `0x020A`, and `1` for every other element, including the ones Outlook 2000 added.
* `+0x28`: the string ID of the UI text, for example "with %s in the subject". Two more strings come from it: text + `0x3E8` is the placeholder shown underlined until a value is chosen ("specific words"), and text + `0x7D0` is the prompt in the edit dialog ("Specify a word or phrase to search for in the subject:").

The definition class is `CRuleComponent` (runtime class `0x10084F00`, size `0x30`). For `0x0064` the placeholder is "message" and the prompt is "Select a message type:".

Pair is a pair of masks that decide where the wizard offers an element **[O97]**:

* The first value is the **item types** the element applies to, matched against the rule's `0x0064` ItemTypes ([§6.2](#62-itemtypeparameter)).
* The second value is the **events** it can be used with, matched against the rule's `0x0190` flags ([§6.1](#61-eventparameter)): `0x1` = arrives, `0x4` = sent.

The rule's own mask is built from those two elements. An element is offered, and a rule is consistent, only if both of its values overlap the rule's. For example, "notify me when it is read" and "Cc the message to" have events `4`, so they're only offered for rules on sent messages. Bit `0x2` of either value is never set in the rule's mask by Outlook 97. In the item-type value it would be an item type Outlook 97 never defines. In the event value, the rule's events are copied as `0x1` → `0x1` and `0x4` → `0x4`, and the third event ("after the server receives", `0x8`) is never mapped. **[Inferred]** Bit `0x2` was meant for that third event.

| ID | Group | Kind | Pair | Client-only | `+0x20`/`+0x24` | Outlook 97 text |
|---|---|---|---|---|---|---|
| `0x0064` | I | `0x0E` item type | 7, 7 | | 1/1 | For each %s |
| `0x00C8` | C | — | 7, 3 | | 1/1 | sent directly to me |
| `0x00C9` | C | — | 7, 3 | | 1/1 | sent only to me |
| `0x00CA` | C | — | 7, 3 | | 1/1 | where my name is not in the To box |
| `0x00CB` | C | `0x01` address (OR) | 7, 3 | | 1/1 | from %s |
| `0x00CC` | C | `0x01` address (OR) | 7, 7 | | 1/1 | sent to %s |
| `0x00CD` | C | `0x09` words | 7, 7 | | 1/1 | with %s in the subject |
| `0x00CE` | C | `0x09` words | 5, 7 | | 1/1 | with %s in the body |
| `0x00CF` | C | `0x09` words | 5, 7 | | 1/1 | with %s in the subject or body |
| `0x00D0` | C | `0x11` flag (condition) | 1, 3 | | 1/1 | flagged for %s |
| `0x00D2` | C | `0x06` importance | 7, 7 | | 1/1 | marked as %s |
| `0x00D3` | C | `0x07` sensitivity | 7, 7 | | 1/1 | marked as %s |
| `0x00D7` | C | `0x08` category | 7, 7 | ✓ | 1/1 | assigned to %s |
| `0x00DC` | C | — | 7, 3 | | 1/1 | which is an Out of Office message |
| `0x00DE` | C | — | 1, 7 | | 1/1 | which has an attachment |
| `0x00DF` | C | `0x13` form properties | 1, 7 | ✓ | 1/1 | with %s of documents or forms |
| `0x00E0` | C | `0x14` size | 1, 7 | | 1/1 | with a size %s |
| `0x00E1` | C | `0x15` time | 1, 3 | | 1/1 | received %s |
| `0x00E2` | C | — | 7, 3 | | 1/1 | where my name is in the Cc box |
| `0x00E3` | C | — | 7, 3 | | 0/0 | where my name is in the To or Cc box |
| `0x00E4` | C | `0x17` form type | 1, 7 | | 1/0 | uses the %s form |
| `0x00E5` | C | `0x09` words | 1, 7 | ✓ | 1/0 | with %s in the recipient's address |
| `0x00E6` | C | `0x09` words | 1, 1 | | 1/0 | with %s in the sender's address |
| `0x012C` | A | `0x04` folder | 7, 3 | | 1/1 | move it to the %s folder |
| `0x012D` | A | — | 7, 3 | | 1/1 | delete it |
| `0x012E` | A | `0x02` address (AND) | 7, 3 | | 1/1 | forward it to %s |
| `0x012F` | A | `0x05` path | 7, 3 | ✓ | 1/1 | reply using %s |
| `0x0130` | A | `0x0A` message | 7, 3 | ✓ | 1/1 | notify me using %s |
| `0x0131` | A | `0x0C` flag (action) | 7, 7 | ✓ | 1/1 | flag message for %s |
| `0x0132` | A | — | 7, 3 | ✓ | 1/1 | clear the Message Flag |
| `0x0133` | A | `0x08` category | 7, 7 | ✓ | 1/1 | assign it to the %s category |
| `0x0136` | A | `0x0D` path | 7, 3 | ✓ | 1/1 | play %s |
| `0x0137` | A | `0x06` importance | 7, 7 | ✓ | 1/1 | mark it as %s |
| `0x0138` | A | `0x07` sensitivity | 7, 4 | ✓ | 1/1 | mark it as %s |
| `0x0139` | A | `0x04` folder | 7, 7 | | 1/1 | move a copy to the %s folder |
| `0x013A` | A | — | 7, 4 | ✓ | 1/1 | notify me when it is read |
| `0x013B` | A | — | 7, 4 | ✓ | 1/1 | notify me when it is delivered |
| `0x013C` | A | `0x10` address (AND, Cc) | 7, 4 | | 1/1 | Cc the message to %s |
| `0x013E` | A | `0x12` defer | 7, 4 | ✓ | 1/0 | defer delivery by %s minutes |
| `0x013F` | A | `0x16` custom action | 7, 7 | ✓ | 1/0 | perform %s |
| `0x0140` | A | — | 0, 0 | | 0/0 | *(none)* |
| `0x0190` | E | `0x0F` event | 7, 7 | | 1/1 | Apply this rule %s |

Each exception `0x01F4`–`0x0212` has the same kind as its condition (+300). Its text is the "except …" form, for example "except if sent directly to me".

### D.2 Parameter classes

| Kind | Used by | Layout after Reserved |
|---|---|---|
| `0x01`, `0x02`, `0x10` | address elements | ADRLIST, MatchAny, IsCc ([§6.4](#64-addressparameter)) |
| `0x04` | folders | [§6.19](#619-folderparameter) |
| `0x05`, `0x08`, `0x09`, `0x0A`, `0x0D` | path, category, words, message, sound | one CString |
| `0x06` / `0x07` | importance / sensitivity | `u32` |
| `0x0C`, `0x11` | flag action / flagged-for condition | Days, Action, IsCondition ([§6.21](#621-flagparameter)) |
| `0x0E` | `0x0064` | ItemTypes, default `1` |
| `0x0F` | `0x0190` | event Flags |
| `0x12`, `0x14`, `0x15`, `0x16`, `0x17` | defer, size, time, custom action, form type | [§6](#6-parameters) |
| `0x13` | form properties | CString, `CArray` of 112-byte document-property objects, then the message-class list |

### D.3 Server rules

A rule can run on the Exchange server only if all three of these hold **[O97]**:

* it has at least one action;
* none of its elements is client-only (`+0x1C`); and
* it doesn't run "after I send the message" (event flag `0x4`).

Otherwise Outlook warns that the rule "is a client-only rule, and will process only when Outlook is running".

### D.4 The rule evaluator

The client-side evaluator (`0x100122CF`) switches on the element ID and runs one test against the message. Message-class tests: "is a meeting" means `IPM.Appointment` or `IPM.Schedule.Meeting.Request`; "is a task" means `IPM.Task` or `IPM.TaskRequest`. "Sent directly to me" reads `PR_MESSAGE_TO_ME`, and "my name in the Cc box" reads `PR_MESSAGE_CC_ME`.

The evaluator also handles IDs that aren't in the definition table, so the wizard can't create them:

| ID | Exception | Test |
|---|---|---|
| `0x00D4` | `0x0200` | my name is in the To box **and** it is a meeting |
| `0x00D5` | `0x0201` | my name is **not** in the To box **and** it is a meeting |
| `0x00DA` | `0x0206` | sent to the element's addresses as Cc recipients: the recipient test with `PR_RECIPIENT_TYPE` = 2 (`MAPI_CC`) |
| `0x00DB` | `0x0207` | sent to the element's addresses: the same recipient test as "sent to" (`0x00CC`), with type 1 (`MAPI_TO`) |

None of these IDs is in Outlook 97's definition table, so Outlook 97 can't load a file that contains them. Readers SHOULD still accept them.

### D.5 Saving and exporting

| Operation | Code | Layout written |
|---|---|---|
| Save to the profile | `0x1003E031` | Signature `970102`; the eight header fields of [§4.2](#42-rulesheader) from the application's settings; `WriteCount` + each rule; then the footer (template directory length and bytes, timestamp, Unknown). |
| Export Rules | `0x10039E30` | `WriteCount` + each rule (G0). |
| Load from the profile | `0x1000C713` | Rejects versions below 960706 or above 970102. |

## Appendix E. Findings from Outlook 98

`OUTLLIB.DLL` comes from `EN/OL98/CORE*.CAB` on the Outlook 98 CD. Its Rules Wizard extension is registered in `rwiz1.ecf` (`Path="OUTLLIB.DLL"`, `Entry Point=ExchEntryPoint`). The file is LZX-compressed across four cabinets and was extracted with `cabextract`.

**Serialization.** Outlook 98 doesn't use MFC's `CArchive`. It reimplements the same byte format on top of its own stream class, with one routine for both loading and storing:

* `CRule::Serialize` (`0x6E454A21`) handles the name (split on a tab into rule and template names), Enabled, Unknown1, ServerRule, then the Flags (only from 970812), then the element list.
* The element list (`0x6E454B20`) reads the count and, for each element, the object tag (`0xFFFF` plus class descriptor, or a class reference), then calls the element's serializer.
* Each element (`0x6E454C69`) reads its ID, looks up the definition, reads the has-parameter flag, and creates and serializes at most one parameter.

**Versions.** The current version is kept at app `+0x134`. Outside the loader, three fields depend on it: the folder SecondaryStore (≥ 970718), the rule Flags (≥ 970812) and DocumentProperty MatchIfMissing (≥ 970102). The loader (`0x6E4547C2`) accepts 960706–970812 and applies the same footer gates as Outlook 97. Importing an unsigned (G0) file treats it as version 970102 (`0x6E77767B`). The full list is in [§4.1.1](#411-version-dependent-fields).

**Header.** The header fields map to app fields U1 `+0x38`, U2 `+0x60`, U3 `+0x64`, U4 `+0x3C`, U5 `+0x18`, U6 `+0x1C`, U7 `+0x20` and U8 `+0x24`. A new profile starts with U1–U4 = 0.

**Element definitions.** Outlook 98 builds its definitions from five static tables of 40-byte records, built by `0x6E45444B`:

| Table | Address | Records |
|---|---|---|
| item type (`0x0064`) | `0x6E4553A0` | 1 |
| conditions | `0x6E4553C8` | 27 |
| actions | `0x6E455800` | 21 |
| exceptions | `0x6E455B48` | 23 |
| event (`0x0190`) | `0x6E455EE0` | 1 |

Each record is ID, group, kind, order, string ID, item-type mask (u16), event mask (u16), `+0x20` flag, client-only, `+0x24` flag, and UI text ID: the same fields as Outlook 97's definitions (Appendix D.1). The tables list elements in the order the wizard shows them.

Compared with Outlook 97, Outlook 98 adds:

* conditions `0x00E7` (hidden), `0x00E8` (message header), `0x00E9`, `0x00EB` and `0x00EC` (junk mail, parameter kinds `0x18`, `0x1A` and `0x1B`, all client-only);
* actions `0x0141` (hidden), `0x0142` (stop processing more rules) and `0x0143` (do not search for commercial or adult content);
* exception `0x0213` (message header).

Relevance (`0x00ED`, `0x0145`) isn't in Outlook 98, so it arrived with Outlook 2000.

**Importing Exchange server rules** (`0x6E77751B`). `PR_RULE_STATE`'s `ST_ENABLED` (`0x1`) and `ST_EXIT_LEVEL` (`0x10`) become Enabled and a "stop processing more rules" action. The rule Flags are restored from offset `0x18` of the rule's provider data.

**Saving rules to the Exchange server** (`0x6E776D15`, `0x6E77FB3A`). Each rule becomes a server rule with these properties:

* `PR_RULE_SEQUENCE`, from a running counter;
* `PR_RULE_STATE`, with `ST_EXIT_LEVEL` added when the rule stops processing;
* `PR_RULE_CONDITION` and `PR_RULE_ACTIONS`;
* `PR_RULE_PROVIDER`, `PR_RULE_LEVEL` and `PR_RULE_NAME`;
* `PR_RULE_PROVIDER_DATA`, laid out as follows.

| Offset | Size | Field |
|---|---|---|
| `0x00` | 4 | Version: `1`, or `970812` when a serialized rule follows. |
| `0x04` | 4 | `0`. |
| `0x08` | 8 | A timestamp (OLE date). |
| `0x10` | variable | Version 970812 only: the whole rule serialized in this file format (a RuleHeader and its elements, [§4.3](#43-rule)). Outlook 98 embeds it when the rule has parts the server can't run. The property's size is `0x18` + the rule's length. |
| `0x18` | 4 | Version 1 only, when the rule's Flags are non-zero: the Flags. The property is then `0x1C` bytes; otherwise `0x18`. |

## Appendix F. Findings from Outlook 2000

The CD image (an Alcohol 120% `.mdf`, a Turkish Outlook 2000) stores raw 2448-byte sectors with 2048 data bytes at offset 16. `PFILES/MSOFFICE/OFFICE/OUTLLIB.DLL` holds the code. From Outlook 2000 on, the UI strings and dialogs are in a separate resource DLL (`1055/OUTLLIBR.DLL` for Turkish), with the same string IDs as before.

* **Serialization.** Serializers now take the stream's version as an argument. The only version checks on fields are the same as Outlook 98's ([§4.1.1](#411-version-dependent-fields)), so the Outlook 2000 format adds no fields. Every structure in this document was checked against Outlook 2000's code: header (`0x3A528E9B`), rule (`0x3A52830D`), element list (`0x3A528426`), element (`0x3A528652`), and every parameter kind. Apart from the differences noted in each section (marked **[O2000]**), they match.
* **Save version** (`[rules + 0x130]`). 970812 for a new profile, the loaded stamp (at least 970102) after a load, and 980413 once the user accepts a rule that needs it ([§4.1.2](#412-how-outlook-2000-chooses-the-stamp)). The check that a rule can be saved at a version is `0x3A526103`, which asks each element's definition (`0x3A526149`).
* **Version check** (`0x3A529056`). A stamp of 1000000 or more is refused, and a stamp newer than 980413 gets a warning.
* **Element reader** (`0x3A5286D9`). It reads the ID, rewrites `0x00EA` as `0x00EB`, looks up the definition (`0x3A52663B`: conditions `0x00C8`–`0x00EE`, actions `0x012C`–`0x014A`; anything else fails the load), then reads NumberOfParameters as a **count** and that many parameters. The writer writes the count of the element's parameter list, or at most 1 at version 970812.
* **Built-in rules** (`0x3A8723C6`, table at `0x3A4FE7E0`). The junk-mail rules and their flags ([§4.3.1.1](#4311-rule-flags)). The `#NET FOLDERS#` rule is created by `0x3A528163`: elements `0x00E7` and `0x0141`, added to the rules, and found again by name.
* **Running client rules** (`0x3A873D94`). The action switch is at `0x3A873EF9`. A failing action sets RuleHeader Unknown1 to `1` and disables the rule ([§4.3.1](#431-ruleheader)).
* **Download Options** (dialog 1129, `0x3A86F375`). Builds the large-message rule with Flags `0x40`.
* **Definition tables** (40-byte records, the same layout as Outlook 98's): item type `0x3A5271A8`, conditions `0x3A5271D0` (29), actions `0x3A527658` (28), exceptions `0x3A527AB8` (24), event `0x3A527E78`.
* **New elements:** `0x00ED` (relevance range, client-only), `0x00EE` and `0x0214` (account, client-only), `0x0144` (redirect), `0x0145` (add to relevance, client-only), `0x0146` (server reply), `0x0147` (forward as attachment), `0x0148` (print, client-only), `0x0149` (start application, client-only) and `0x014A` (permanently delete, client-only). "Play a sound" (`0x0136`) moved to a new parameter class with the same layout.
* **Parameter factory** (jump table `0x3A5269F4`, kinds 1–`0x20`). New kinds: `0x1C` add to relevance (Reserved, u32), `0x1D` server reply (Reserved, entry ID, String), `0x1E` account (Reserved, String, String), and `0x1F`/`0x20` sound and application paths (Reserved, String). Every other kind's layout is unchanged from Outlook 98.

## References

1. https://support.microsoft.com/en-us/office/manage-email-messages-by-using-rules-c24f5dea-9465-4df4-ad17-a50704d66c59
2. https://www.computerhope.com/download/updates.htm
3. https://www.slipstick.com/outlook/rules/rules-wizard/
4. https://www.itprotoday.com/email-and-calendaring/how-do-you-delete-and-recreate-corrupt-outlook-rules
5. https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxprops/f1fbd19a-9b2c-4c16-a07b-2242b2c0dece
6. https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxorule/950a82ff-acde-40b3-8f2f-fc46ceb7a182
7. https://learn.microsoft.com/en-us/office/client-developer/outlook/mapi/contents-tables
8. https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxorule/ee0fd52b-1161-49b8-adab-6b8c2e31c3f3
