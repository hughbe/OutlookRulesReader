# OutlookRulesReader

OutlookRulesReader is a reader of Outlook rules (rwz) files.

## Outlook Rules Wizard File (.rwz) Specification
A PDF of the working specification for Outlook rules files (.rwz) files can be found [here](https://github.com/hughbe/OutlookRulesReader/raw/master/docs/RWZ%20Format.pdf).

## Installation

OutlookRulesReader is a Swift package. You can't import it from a single `.swift` file run with `swift file.swift`, so create a package that depends on it.

1. Create a new executable package:

   ```sh
   mkdir RulesDump && cd RulesDump
   swift package init --type executable --name RulesDump
   ```

2. Add OutlookRulesReader as a dependency in `Package.swift`:

   ```swift
   // swift-tools-version:5.3
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

Each rule has a `name`, an `enabled` flag, and `conditions`, `actions` and `exceptions`. Each of those is a `RuleElement` with an `identifier` (what the element is) and `parameters` (its details). Cast `element.parameter` to the matching type, such as `StringParameter`, `FolderParameter` or `AddressParameter`, to read them. See the [tests](Tests/OutlookRulesReaderTests) for an example of every kind of condition, action and exception.

Rules can also be written back to a file:

```swift
let newData = rules.getData()
```

`getData(version:)` writes the file in the format of a specific Outlook version, such as `.outlook2007`.

## Contributing
All contributions to the specification and the implementation library are welcome and encouraged!
