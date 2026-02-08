import AppIntents
import Foundation

// MARK: - Entity

extension Checklist: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Checklist"
    static var defaultQuery = ChecklistQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// MARK: - Query

struct ChecklistQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [Checklist] {
        let byID = Dictionary(uniqueKeysWithValues: ChecklistStore.loadChecklists().map { ($0.id, $0) })
        return identifiers.compactMap { byID[$0] }
    }

    func suggestedEntities() async throws -> [Checklist] {
        ChecklistStore.loadChecklists()
    }

    func entities(matching string: String) async throws -> [Checklist] {
        ChecklistStore.loadChecklists().filter {
            $0.name.localizedCaseInsensitiveContains(string)
        }
    }
}

// MARK: - Intent

struct GetChecklistItemsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Checklist Items"
    static var description = IntentDescription("Shows the items on a checklist.")
    static var openAppWhenRun = false

    @Parameter(title: "Checklist")
    var checklist: Checklist

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let lists = ChecklistStore.loadChecklists()
        guard let list = lists.first(where: { $0.id == checklist.id }) else {
            return .result(dialog: "I couldn't find that checklist.")
        }

        let unchecked = list.fields.filter { !$0.isChecked }

        if unchecked.isEmpty {
            return .result(dialog: "Everything is checked off on \(list.name).")
        }

        let items = unchecked.map(\.name).joined(separator: ", ")
        return .result(dialog: "\(list.name) has \(unchecked.count) items: \(items)")
    }
}

// MARK: - Shortcuts

struct ChecklistShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetChecklistItemsIntent(),
            phrases: [
                "What's on my \(\.$checklist) in \(.applicationName)",
                "Show my \(\.$checklist) in \(.applicationName)",
            ],
            shortTitle: "Get Checklist Items",
            systemImageName: "checklist"
        )
    }
}
