# OutlookRulesReader

OutlookRulesReader reads and writes Outlook rules (.rwz) files, the files made by Outlook's **Export Rules**.

## Features

- **Every format:** Outlook 97 through Outlook 2019 and Microsoft 365, which still writes the Outlook 2010 format. Files can be converted between formats; like Outlook, converting to an older format leaves out rules that format can't store.
- **Every condition, action and exception** Outlook defines (115 kinds), with typed parameters.
- **Readable rules:** `rule.text` describes a rule in the Rules Wizard's own words.
- **Exact round trips:** every file that reads is written back byte for byte, so rules can be edited without disturbing anything else.
- **Safe on any input:** malformed files throw a specific error and never crash. This is checked by fuzzing every sample file. Rules from newer versions of Outlook that the library can't read are kept rather than failing the file.
- **Tested** on macOS and Linux against 330 sample files exported from real versions of Outlook.

## Outlook Rules Wizard File (.rwz) Specification
The specification for Outlook rules (.rwz) files is in [spec/Rules.md](spec/Rules.md). It records which details have been verified against the sample files in `Tests/OutlookRulesReaderTests/Resources`, which are inferred, and which are still unknown. Earlier experimental notes are in [docs/RWZ Format.pdf](docs/RWZ%20Format.pdf).

## Installation

OutlookRulesReader is a Swift package. You can't import it from a single `.swift` file run with `swift file.swift`, so create a package that depends on it.

1. Create a new executable package:

   ```sh
   mkdir RulesDump && cd RulesDump
   swift package init --type executable --name RulesDump
   ```

2. Add OutlookRulesReader as a dependency in `Package.swift`:

   ```swift
   // swift-tools-version:5.5
   import PackageDescription

   let package = Package(
       name: "RulesDump",
       dependencies: [
           .package(name: "OutlookRulesReader", url: "https://github.com/hughbe/OutlookRulesReader", .branch("main")),
       ],
       targets: [
           .target(name: "RulesDump", dependencies: ["OutlookRulesReader"]),
       ]
   )
   ```

   (Once a release newer than `1.0.0` is tagged, use `from: "<version>"` instead of `.branch("main")`.)

3. Replace the contents of `Sources/RulesDump/main.swift` with the example below.

4. Run it, passing the path to your rules file:

   ```sh
   swift run RulesDump ~/Documents/MyRules.rwz
   ```

To get a `.rwz` file, use **File → Manage Rules & Alerts → Options → Export Rules…** in Outlook for Windows.

## Example Usage

This reads a rules file and prints each rule the way Outlook's Rules Wizard describes it:

```swift
import Foundation
import OutlookRulesReader

guard CommandLine.arguments.count > 1 else {
    print("usage: RulesDump <path-to-file>.rwz")
    exit(1)
}

let rules = try OutlookRules(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
for rule in rules.rules {
    print("\(rule.name)\(rule.enabled ? "" : " (disabled)")")
    print(rule.text)
    print()
}
```

Example output:

```
Invoices
Apply this rule after the message arrives
from Hugh Bellamy or Accounts
and with 'invoice' or 'bill' in the subject
assign it to the Finance category
and stop processing more rules
except if it has an attachment
```

`rule.text` uses the wording Outlook's Rules Wizard uses for each condition, action and exception, recorded in the specification. `element.text` describes a single element, and `identifier.textTemplate` gives the wording with its placeholder, such as "from *people or public group*".

To work with the details instead, cast `element.parameter` to its type:

```swift
for rule in rules.rules {
    for element in rule.conditions + rule.actions + rule.exceptions {
        if let words = element.parameter as? StringParameter {
            print("\(element.identifier): \(words.value)")
        } else if let folder = element.parameter as? FolderParameter {
            print("\(element.identifier): \(folder.folderName)")
        } else if let addresses = element.parameter as? AddressParameter {
            print("\(element.identifier): \(addresses.recipients.compactMap { $0.displayName })")
        }
    }
}
```

Each rule has a `name`, an `enabled` flag, and `conditions`, `actions` and `exceptions`. Rules made with the Outlook 97 Rules Wizard also record the wizard template they came from in `templateName`. Each of those is a `RuleElement` with an `identifier` (what the element is) and `parameters` (its details). Cast `element.parameter` to the matching type, such as `StringParameter`, `FolderParameter` or `AddressParameter`, to read them. See the [tests](Tests/OutlookRulesReaderTests) for an example of every kind of condition, action and exception. `identifier.parameterType` says which parameter type an element takes, and `print(rules)` prints every rule with its elements and parameters.

People and public groups (`AddressParameter`) are lists of MAPI properties. `recipients` decodes the common ones: `displayName`, `addressType`, `emailAddress`, `smtpAddress`, `entryId` and `recipientType`.

Folders, templates and address books are identified by MAPI entry IDs. These are kept exactly as stored (`folderEntryIdBytes`, `storeEntryIdBytes`, `messageEntryIdBytes`, `entryIdBytes`) and decoded on demand (`folderEntryId` and so on), which is nil for an entry ID that can't be decoded.

Every file the library reads is written back byte for byte, including values Outlook itself never writes, such as a boolean stored as 5. The `Bool` properties are backed by `raw…` properties that hold the stored value.

Rules can be edited and written back to a file. The rest of the file (template directory, server settings) is kept:

```swift
var rules = try OutlookRules(contentsOf: URL(fileURLWithPath: "Rules.rwz"))
rules.rules[0].enabled = false
rules.rules.append(Rule(eventFlags: .afterReceived, name: "Tidy invoices", conditions: [
    RuleElement(identifier: .specificWordsInSubjectCondition, parameter: StringParameter(value: "invoice"))
], actions: [
    RuleElement(identifier: .deleteAction)
]))
try rules.write(to: URL(fileURLWithPath: "Rules.rwz"))
```

`getData()` returns the file's bytes instead. `write(to:version:)` and `getData(version:)` write the file in the format of a specific Outlook version, such as `.outlook2007`.

Like Outlook's own Export Rules, writing to an older format leaves out every rule that contains a condition, action or exception that format can't store, since that version of Outlook would fail to load the file. `unsupportedRules(in:)` lists the rules that would be left out.

### Errors

A file that can't be read throws an `OutlookRulesReadError` saying why, such as `unknownElement(identifier:)` or `dataSizeMismatch(dataSize:actualSize:)`, or `DataStreamError.noSpace` if it ends early. Malformed input throws; it never crashes.

In the Outlook 2002 and later formats, each rule records its size, so a rule whose elements this library can't read (for example, one using an element from a later version of Outlook) is kept rather than failing the whole file. Its `unparsedReason` says why, and it is written back unchanged.

## Contributing
All contributions to the specification and the implementation library are welcome and encouraged!
