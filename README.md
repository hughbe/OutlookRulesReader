# OutlookRulesReader

OutlookRulesReader is a reader of Outlook rules (rwz) files.

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

This reads a rules file and prints each rule with its conditions, actions and exceptions:

```swift
import Foundation
import OutlookRulesReader

guard CommandLine.arguments.count > 1 else {
    print("usage: RulesDump <path-to-file>.rwz")
    exit(1)
}

let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let rules = try OutlookRules(data: data)

for (index, rule) in rules.rules.enumerated() {
    print("Rule \(index + 1): \(rule.name) (\(rule.enabled ? "enabled" : "disabled"))")

    let sections = [("Conditions", rule.conditions), ("Actions", rule.actions), ("Exceptions", rule.exceptions)]
    for (title, elements) in sections where !elements.isEmpty {
        print("  \(title):")
        for element in elements {
            var line = "    \(element.identifier)"
            // Parameters hold the details of an element, such as the words to look for.
            if let words = element.parameter as? StringParameter {
                line += ": \(words.value)"
            } else if let folder = element.parameter as? FolderParameter {
                line += ": \(folder.folderName)"
            } else if let categories = element.parameter as? CategoryParameter {
                line += ": \(categories.categories.joined(separator: ", "))"
            } else if let addresses = element.parameter as? AddressParameter {
                line += ": \(addresses.recipients.compactMap { $0.displayName }.joined(separator: ", "))"
            }
            print(line)
        }
    }
}
```

Example output:

```
Rule 1: RULE2 (enabled)
  Actions:
    flagAction
Rule 2: RULE1 (enabled)
  Conditions:
    automaticReplyCondition
```

Each rule has a `name`, an `enabled` flag, and `conditions`, `actions` and `exceptions`. Rules made with the Outlook 97 Rules Wizard also record the wizard template they came from in `templateName`. Each of those is a `RuleElement` with an `identifier` (what the element is) and `parameters` (its details). Cast `element.parameter` to the matching type, such as `StringParameter`, `FolderParameter` or `AddressParameter`, to read them. See the [tests](Tests/OutlookRulesReaderTests) for an example of every kind of condition, action and exception. `identifier.parameterType` says which parameter type an element takes, and `print(rules)` prints every rule with its elements and parameters.

People and public groups (`AddressParameter`) are lists of MAPI properties. `recipients` decodes the common ones: `displayName`, `addressType`, `emailAddress`, `smtpAddress`, `entryId` and `recipientType`.

Folders, templates and address books are identified by MAPI entry IDs. These are kept exactly as stored (`folderEntryIdBytes`, `storeEntryIdBytes`, `messageEntryIdBytes`, `entryIdBytes`) and decoded on demand (`folderEntryId` and so on), which is nil for an entry ID that can't be decoded.

Every file the library reads is written back byte for byte, including values Outlook itself never writes, such as a boolean stored as 5. The `Bool` properties are backed by `raw…` properties that hold the stored value.

Rules can be edited and written back to a file. The rest of the file (template directory, server settings) is kept:

```swift
var rules = try OutlookRules(data: data)
rules.rules[0].enabled = false
rules.rules.append(Rule(eventFlags: .afterReceived, name: "Tidy invoices", conditions: [
    RuleElement(identifier: .specificWordsInSubjectCondition, parameter: StringParameter(value: "invoice"))
], actions: [
    RuleElement(identifier: .deleteAction)
]))
let newData = rules.getData()
```

`getData(version:)` writes the file in the format of a specific Outlook version, such as `.outlook2007`.

Like Outlook's own Export Rules, writing to an older format leaves out every rule that contains a condition, action or exception that format can't store, since that version of Outlook would fail to load the file. `unsupportedRules(in:)` lists the rules that would be left out.

### Errors

A file that can't be read throws an `OutlookRulesReadError` saying why, such as `unknownElement(identifier:)` or `dataSizeMismatch(dataSize:actualSize:)`, or `DataStreamError.noSpace` if it ends early. Malformed input throws; it never crashes.

In the Outlook 2002 and later formats, each rule records its size, so a rule whose elements this library can't read (for example, one using an element from a later version of Outlook) is kept rather than failing the whole file. Its `unparsedReason` says why, and it is written back unchanged.

## Contributing
All contributions to the specification and the implementation library are welcome and encouraged!
