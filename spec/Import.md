# Importing Rules from Outlook Express

This document describes how Outlook 2002–2010 import mail rules from Outlook Express and Windows Mail, and how each Outlook Express criterion and action becomes a rule element. It is a companion to the [file format specification](Rules.md), whose [Rules §7](Rules.md#7-elements) lists the elements.

As in the format specification, a statement about an Outlook version was read from that version's code, and the addresses are in [Decompilation notes](Decompilation.md).

Outlook 2002's Import and Export Wizard can import mail rules from Outlook Express 4 and 5 ("Outlook Import Tool" → "Import Rules"). The work is split between two DLLs:

* `IMPMAIL.DLL` (`ImportRules` export) reads the Outlook Express rules.
* `OUTLLIB.DLL`'s `HrImportRules` export loads `IMPMAIL.DLL` and calls `ImportRules` with a table of callbacks. IMPMAIL creates a rule, its elements and their values through those callbacks, so it never writes this file format itself.

Each imported rule is created **turned off**. When the import finishes, Outlook says "Rules and Filters were successfully imported. To enable and edit these rules please launch the Rules Wizard." A rule containing any criterion or action without an Outlook equivalent is left out completely, never partly imported.

**Element codes.** IMPMAIL asks for elements by code, and Outlook maps the codes to identifiers:

| Condition code | Element | | Action code | Element |
|---|---|---|---|---|
| 0, 1 | `0x00CC` sent to | | 1 | `0x012C` move to folder |
| 2 | `0x00CB` from | | 2 | `0x0139` copy to folder |
| 3 | `0x00CD` words in subject | | 3 | `0x012F` reply using template |
| 4 | `0x00E0` size | | 7 | `0x012E` forward |
| 5 | `0x00E5` words in recipient's address | | 9 | `0x0131` flag message |
| 6 | `0x00E6` words in sender's address | | 10 | `0x012D` delete it |
| 7 | `0x00CE` words in body | | 100 | `0x0142` stop processing more rules |
| 8 | `0x00DE` has an attachment | | | |
| 9 | `0x00D2` importance | | | |

**Outlook Express 4.** Rules are registry keys under `HKCU\Software\Microsoft\Outlook Express\Mail\Inbox Rules`, one subkey per rule. Each is named "Outlook Express rule #*n*", because Outlook Express 4 rules have no names.

| Value | Becomes |
|---|---|
| `All Messages` | No conditions. |
| `To`, `CC` | Addresses added to one "sent to" (`0x00CC`) condition. |
| `From` | "from" (`0x00CB`). |
| `Subject` | "with words in the subject" (`0x00CD`). |
| `Size` | "with a size in a specific range" (`0x00E0`), from *Size* + 1 KB to 999999 KB. |
| `Account` | Ignored. |
| `Actions` | A bitmask: `0x01` move to the folder in `Move To Handle`, `0x02` copy to the folder in `Copy To Handle`, `0x04` forward to the addresses in `Forward To`, `0x08` reply using the file in `Reply With File`, `0x20` delete. A rule with `0x10` is not imported. |

**Outlook Express 5.** Rules come from Outlook Express's own rules manager, a COM object (CLSID `{626BAFE0-E5D6-11D1-B1DD-006097D503D9}`). IMPMAIL reads each rule's name (property 0), criteria (property 2: an array of 32-byte items, each with a type and a `PROPVARIANT` value) and actions (property 3: 24-byte items).

| Criterion type | Becomes | | Action type | Becomes |
|---|---|---|---|---|
| 5, 6, 21 | "sent to" (`0x00CC`) | | 1 | copy (`0x0139`) |
| 7 | "from" (`0x00CB`) | | 2 | forward (`0x012E`) |
| 8 | words in subject (`0x00CD`) | | 5 | reply using template (`0x012F`) |
| 9 | words in body (`0x00CE`) | | 6 | move (`0x012C`) |
| 10, 11, 22 | words in recipient's address (`0x00E5`) | | 7 | delete (`0x012D`) |
| 12 | words in sender's address (`0x00E6`) | | 11 | flag (`0x0131`) |
| 13 | importance (`0x00D2`) | | 12 | stop processing more rules (`0x0142`) |
| 14 | has an attachment (`0x00DE`) | | 0, 3, 4, 8–10, 13 | not imported |
| 15 | size (`0x00E0`) | | | |
| 20 | no conditions (all messages) | | | |
| 0–4, 16–19 | not imported | | | |

A criterion whose value is a list (`VT_BLOB` of strings) becomes one word parameter per string ([Rules §8.3](Rules.md#83-wordparameter)).

**Later versions.**

* **Outlook 2003** maps the codes exactly as Outlook 2002 does. Its `IMPMAIL.DLL` (23 July 2003) still reads `Software\Microsoft\Outlook Express\5.0`, and creates the Outlook Express rules manager in the same way. The completion message now points to "Tools | Rules and Alerts".
* **Outlook 2007** maps the codes in the same way. The Import and Export Wizard now offers "Outlook Express 4.x, 5.x, 6.x or Windows Mail". Its `IMPMAIL.DLL` (26 October 2006) no longer contains the Outlook Express 5 registry key, and the "Outlook Express rule #*n*" naming string is gone from the resources. Instead it creates the same Outlook Express rules-manager COM object as Outlook 2003's `IMPMAIL.DLL` and the identity manager (`{A9AE6C90-1D1B-11D2-B21A-00C04FA357FA}`). **[Inferred]** Outlook Express 6 and Windows Mail provide that object, which is how their rules are read. `IMPMAIL.DLL` exports `ImportRules` and names `outlook.exe` and `HrImportRules`; **[Inferred]** it calls `HrImportRules` back to build the Outlook rules. `OUTLOOK.EXE` itself has no `ImportRules` string.
* **Outlook 2010**'s `HrImportRules` now gets the `ImportRules` function from `IMPMAIL.DLL` itself, and fails with `CO_E_ERRORINDLL` (`0x800401F9`) if it is missing. Its callbacks map the codes exactly as Outlook 2002's, and it loads the rules before the import and saves them after. But Outlook 2010's `IMPMAIL.DLL` (14.0.4760.1000) no longer exports `ImportRules` and no longer contains the Outlook Express rules-manager CLSID; it still has the identity manager's CLSID and still names `outlook.exe` and `HrImportRules`. **[Inferred]** So Outlook 2010 can't import Outlook Express or Windows Mail rules, and the mapping is never reached, even though the Import and Export Wizard still offers "Outlook Express 4.x, 5.x, 6.x or Windows Mail" and the resources keep the rule-naming string "Outlook Express or Windows Mail rule #". The dialog "Importing Inbox Rules" and the message "%1 rules imported. Go to Tools | Rules and Alerts…" are gone. The update's `IMPMAIL.DLL` (14.0.7248.5000) still has no `ImportRules` export and no Outlook Express rules CLSID.
* **Outlook 2013** removes the import. `OUTLOOK.EXE` no longer exports `HrImportRules` and has no `ImportRules` or `impmail` string, the code that mapped the codes is gone, and Office 2013 has no `IMPMAIL.DLL`. The resources drop the strings "Outlook Express 4.x, 5.x, 6.x or Windows Mail", "Outlook Express or Windows Mail" and "Outlook Express or Windows Mail rule #", the rules messages, the `Software\Microsoft\Outlook Express` keys, and the dialogs "Outlook Import Tool", "Import Addresses" and "Import Summary". So the Import and Export Wizard no longer offers it.
