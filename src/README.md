# OutlookRulesReader

OutlookRulesReader is a reader of Outlook rules (rwz) files.

Example Usage

```swift
let data = Data(contentsOfFile: "<path-to-file>.rwz")!
let file = try OutlookRulesFile(data: data)
print(file.rules.count)
print(file.rules[0].name)
print(file.rules[0].enabled)
print(file.rules[0].conditions.count)
print(file.rules[0].actions.count)
print(file.rules[0].exceptions.count)
```
