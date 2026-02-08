import Combine
import Foundation

struct Field: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = .init()
    var name: String
    var isChecked: Bool = false
}

struct Checklist: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = .init()
    var name: String
    var fields: [Field] = []
}

final class ChecklistStore: ObservableObject {
    @Published var lists: [Checklist] = [] {
        didSet { save() }
    }

    private static let persistenceURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("checklists.json")
    }()

    private let fileURL: URL

    init() {
        fileURL = Self.persistenceURL
        load()
    }

    // MARK: - List operations

    func addList(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lists.append(Checklist(name: trimmed))
    }

    func deleteLists(at offsets: IndexSet) {
        lists.remove(atOffsets: offsets)
    }

    func moveLists(from source: IndexSet, to destination: Int) {
        lists.move(fromOffsets: source, toOffset: destination)
    }

    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
    }

    // MARK: - Static Access for App Intents

    static func loadChecklists() -> [Checklist] {
        readLists(from: persistenceURL)
    }

    // MARK: - Persistence

    private static func readLists(from fileURL: URL) -> [Checklist] {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Checklist].self, from: data)
        {
            return decoded
        }
        let legacyURL = fileURL.deletingLastPathComponent().appendingPathComponent("checklist.json")
        if let legacyData = try? Data(contentsOf: legacyURL),
           let legacyFields = try? JSONDecoder().decode([Field].self, from: legacyData)
        {
            return [Checklist(name: "My Checklist", fields: legacyFields)]
        }
        return []
    }

    func load() {
        lists = Self.readLists(from: fileURL)
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(lists)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Ignored for simplicity
        }
    }
}
