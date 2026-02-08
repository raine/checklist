import Foundation

enum MarkdownParser {
    /// Converts checklists to markdown format
    static func formatMarkdown(_ checklists: [Checklist]) -> String {
        var lines: [String] = []
        for checklist in checklists {
            if !lines.isEmpty {
                lines.append("")
            }
            lines.append("# \(checklist.name)")
            lines.append("")
            for field in checklist.fields {
                lines.append("- \(field.name)")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Parses markdown into checklists
    /// - Headings (# ) become checklist names
    /// - List items (-, *, +) become fields
    /// - Checkbox syntax ([ ] or [x]) is stripped
    /// - Items before first heading go into "Imported Checklist"
    /// - Duplicate titles are made unique by appending a number
    static func parseMarkdown(_ text: String) -> [Checklist] {
        var checklists: [Checklist] = []
        var currentChecklist: Checklist?
        var usedNames: Set<String> = []

        func uniqueName(for name: String) -> String {
            var candidate = name
            var counter = 2
            while usedNames.contains(candidate) {
                candidate = "\(name) \(counter)"
                counter += 1
            }
            usedNames.insert(candidate)
            return candidate
        }

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("# ") {
                // Save previous checklist if exists
                if let current = currentChecklist {
                    checklists.append(current)
                }
                let rawName = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let name = uniqueName(for: rawName.isEmpty ? "Imported Checklist" : rawName)
                currentChecklist = Checklist(name: name)
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                // Support all markdown bullet styles: -, *, +
                var itemText = String(trimmed.dropFirst(2))

                // Strip checkbox syntax: [ ] or [x] or [X]
                if itemText.hasPrefix("[ ] ") {
                    itemText = String(itemText.dropFirst(4))
                } else if itemText.hasPrefix("[x] ") || itemText.hasPrefix("[X] ") {
                    itemText = String(itemText.dropFirst(4))
                }

                itemText = itemText.trimmingCharacters(in: .whitespaces)

                if !itemText.isEmpty {
                    // Create default checklist if none exists
                    if currentChecklist == nil {
                        let name = uniqueName(for: "Imported Checklist")
                        currentChecklist = Checklist(name: name)
                    }
                    currentChecklist?.fields.append(Field(name: itemText))
                }
            }
        }

        // Don't forget the last checklist
        if let current = currentChecklist {
            checklists.append(current)
        }

        return checklists
    }
}
