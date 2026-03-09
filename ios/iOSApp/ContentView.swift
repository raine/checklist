import SwiftUI
import UIKit

struct ImportData: Identifiable {
    let id = UUID()
    let checklists: [Checklist]
}

struct ContentView: View {
    @StateObject private var store = ChecklistStore()
    @State private var showingNewListSheet = false
    @State private var newListName: String = ""
    @State private var importData: ImportData?
    @State private var showingExportConfirmation = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var isDeleteMode = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: Int = AppearanceMode.system.rawValue

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveBackground()
                    .ignoresSafeArea()

                GeometryReader { proxy in
                    let spacing: CGFloat = 16
                    let columnsCount = 2
                    let totalSpacing = spacing * CGFloat(columnsCount - 1)
                    let horizontalPadding = spacing * 2
                    let availableWidth = proxy.size.width - totalSpacing - horizontalPadding
                    let itemSize = floor(availableWidth / CGFloat(columnsCount))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing, alignment: .top), count: columnsCount)
                            LazyVGrid(columns: columns, spacing: spacing) {
                                ForEach(store.lists) { list in
                                    ZStack(alignment: .topLeading) {
                                        if isDeleteMode {
                                            ChecklistCardView(list: list, itemSize: itemSize)
                                        } else {
                                            NavigationLink(destination: ChecklistDetailView(store: store, listID: list.id)) {
                                                ChecklistCardView(list: list, itemSize: itemSize)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        if isDeleteMode {
                                            Button {
                                                store.deleteList(id: list.id)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(.white, Color(.darkGray))
                                            }
                                            .offset(x: -6, y: -6)
                                        }
                                    }
                                    .simultaneousGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onEnded { _ in
                                                isDeleteMode = true
                                            },
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, spacing)
                        .padding(.vertical, spacing)
                        .frame(minHeight: proxy.size.height, alignment: .top)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isDeleteMode = false
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: mainToolbarContent)
            .sheet(isPresented: $showingNewListSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("List Name")) {
                            TextField("e.g. Trip Prep", text: $newListName)
                        }
                    }
                    .navigationTitle("New Checklist")
                    .toolbar(content: newListToolbarContent)
                }
            }
            .sheet(item: $importData) { data in
                ImportPreviewView(
                    checklists: data.checklists,
                    existingNames: Set(store.lists.map(\.name)),
                    onImport: confirmImport,
                    onCancel: {
                        importData = nil
                    },
                )
            }
            .alert(isPresented: $showingExportConfirmation) {
                Alert(
                    title: Text("Copied to Clipboard"),
                    message: Text("Your checklists have been copied as markdown."),
                    dismissButton: .default(Text("OK")),
                )
            }
            .alert(isPresented: $showingImportError) {
                Alert(
                    title: Text("Import Failed"),
                    message: Text(importErrorMessage),
                    dismissButton: .default(Text("OK")),
                )
            }
        }
    }

    @ToolbarContentBuilder
    private func newListToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { showingNewListSheet = false; newListName = "" }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Create") { createList() }
                .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @ToolbarContentBuilder
    private func mainToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("My Checklists")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(AppTheme.navItemColor)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: importFromClipboard) {
                    Label("Import from Clipboard", systemImage: "square.and.arrow.down")
                }
                Button(action: exportToClipboard) {
                    Label("Export to Clipboard", systemImage: "square.and.arrow.up")
                }
                .disabled(store.lists.isEmpty)
                Divider()
                Button(action: {
                    appearanceModeRaw = appearanceMode.next().rawValue
                }) {
                    Label("Appearance: \(appearanceMode.label)", systemImage: appearanceMode.iconName)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(AppTheme.navItemColor)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingNewListSheet = true }) {
                Image(systemName: "plus")
                    .foregroundColor(AppTheme.navItemColor)
            }
        }
    }

    private func createList() {
        store.addList(name: newListName)
        newListName = ""
        showingNewListSheet = false
    }

    private func exportToClipboard() {
        let markdown = MarkdownParser.formatMarkdown(store.lists)
        UIPasteboard.general.string = markdown
        showingExportConfirmation = true
    }

    private func importFromClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            importErrorMessage = "Clipboard is empty"
            showingImportError = true
            return
        }

        let parsed = MarkdownParser.parseMarkdown(text)
        if parsed.isEmpty {
            importErrorMessage = "No checklist items found in clipboard"
            showingImportError = true
            return
        }

        // Setting importData triggers the sheet with the data directly passed
        importData = ImportData(checklists: parsed)
    }

    private func confirmImport() {
        guard let data = importData else { return }

        // Upsert: update existing lists by name, add new ones
        for imported in data.checklists {
            if let existingIndex = store.lists.firstIndex(where: { $0.name == imported.name }) {
                store.lists[existingIndex] = imported
            } else {
                store.lists.append(imported)
            }
        }
        importData = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
