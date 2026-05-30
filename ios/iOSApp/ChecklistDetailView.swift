import SwiftUI
import UIKit

struct ChecklistDetailView: View {
    @ObservedObject var store: ChecklistStore
    let listID: UUID

    @State private var newFieldName: String = ""
    @State private var editMode: EditMode = .inactive

    private var isEditing: Bool { editMode.isEditing }

    private var checklistIndex: Int? {
        store.lists.firstIndex { $0.id == listID }
    }

    private var listBinding: Binding<Checklist>? {
        guard let idx = checklistIndex else { return nil }
        return $store.lists[idx]
    }

    private var allChecked: Bool {
        guard let idx = checklistIndex else { return false }
        let fields = store.lists[idx].fields
        return !fields.isEmpty && fields.allSatisfy(\.isChecked)
    }

    private var checkedCount: Int {
        guard let idx = checklistIndex else { return 0 }
        return store.lists[idx].fields.count(where: { $0.isChecked })
    }

    var body: some View {
        Group {
            if let list = listBinding {
                ChecklistListView(
                    list: list,
                    newFieldName: $newFieldName,
                    isEditing: isEditing,
                    addField: addField,
                    dismissKeyboard: { dismissKeyboard() },
                )
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .tintIfAvailable(AppTheme.navItemColor)
                .accentColor(AppTheme.navItemColor)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if isEditing {
                            TextField("Name", text: list.name)
                                .font(.system(size: 22, weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppTheme.navItemColor)
                        } else {
                            Text(list.wrappedValue.name)
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(AppTheme.navItemColor)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let done = checkedCount
                        let total = list.wrappedValue.fields.count
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Text("\(done)/\(total)")
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                if allChecked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: allChecked)

                            Button(action: {
                                withAnimation(.default) {
                                    if isEditing { dismissKeyboard() }
                                    editMode = isEditing ? .inactive : .active
                                }
                            }) {
                                Image(systemName: isEditing ? "checkmark" : "pencil")
                                    .foregroundColor(AppTheme.navItemColor)
                                    .imageScale(.medium)
                                    .accessibilityLabel(isEditing ? "Done" : "Edit")
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .environment(\.editMode, $editMode)

            } else {
                Text("List not found").foregroundColor(.secondary)
            }
        }
    }

    private func addField() {
        guard let idx = checklistIndex else { return }
        let name = newFieldName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        // Insert at top so new item appears right under the input row
        store.lists[idx].fields.insert(Field(name: name), at: 0)
        newFieldName = ""
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - FocusableTextField for iOS 14+

// MARK: - Extracted editing row to simplify type-checking

private struct EditingFieldRow: View {
    @Binding var field: Field
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            FocusableTextField(
                text: $field.name,
                isFirstResponder: false,
                placeholder: "Field name",
            )
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel("Delete")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(AppTheme.tileText)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.tileBackground)
                .shadow(color: Color.primary.opacity(0.08), radius: 6, x: 0, y: 3),
        )
        .listRowSeparatorHiddenCompat()
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

// MARK: - Display (non-editing) row

private struct DisplayFieldRow: View {
    @Binding var field: Field
    var onDelete: () -> Void

    var body: some View {
        Toggle(isOn: $field.isChecked) {
            Text(field.name)
        }
        .toggleStyle(TileToggleStyle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .tint(Color(hex: 0xD96D6D))
        }
        .listRowBackground(Color.clear)
        .listRowSeparatorHiddenCompat()
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

// MARK: - Quick add row

private struct QuickAddRow: View {
    @Binding var text: String
    var onCommit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .foregroundColor(AppTheme.tileText.opacity(0.35))
                .imageScale(.large)
            FocusableTextField(
                text: $text,
                isFirstResponder: false,
                placeholder: "Add new item",
                shouldResignOnReturn: false,
                onCommit: onCommit,
            )
        }
        .tileStyle()
    }
}

// MARK: - Extracted list content to reduce body complexity

private struct ChecklistListView: View {
    @Binding var list: Checklist
    @Binding var newFieldName: String
    var isEditing: Bool
    var addField: () -> Void
    var dismissKeyboard: () -> Void

    private func deleteField(id: UUID) {
        if let idx = list.fields.firstIndex(where: { $0.id == id }) {
            list.fields.remove(at: idx)
        }
    }

    var body: some View {
        ZStack {
            AdaptiveBackground()
                .ignoresSafeArea()

            List {
                ForEach($list.fields) { $field in
                    let fieldID = $field.wrappedValue.id
                    if isEditing {
                        EditingFieldRow(
                            field: $field,
                            onDelete: { deleteField(id: fieldID) },
                        )
                    } else {
                        DisplayFieldRow(
                            field: $field,
                            onDelete: { deleteField(id: fieldID) },
                        )
                    }
                }
                .onMove { from, to in
                    list.fields.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .listRowSpacingCompat(8)
            .scrollContentBackgroundHidden()
            .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
            .gesture(DragGesture().onChanged { _ in dismissKeyboard() })
            .padding(.top, 16)
            .padding(.bottom, isEditing ? 0 : 88)
            .padding(.horizontal, isEditing ? 16 : 0)

            if !isEditing {
                VStack {
                    Spacer()
                    QuickAddRow(text: $newFieldName, onCommit: addField)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
    }
}

private struct FocusableTextField: UIViewRepresentable {
    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var shouldResignOnReturn: Bool
        var onCommit: (() -> Void)?
        init(text: Binding<String>, shouldResignOnReturn: Bool, onCommit: (() -> Void)?) {
            self.text = text
            self.shouldResignOnReturn = shouldResignOnReturn
            self.onCommit = onCommit
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if shouldResignOnReturn {
                textField.resignFirstResponder()
            }
            onCommit?()
            return true
        }

        func textFieldDidEndEditing(_: UITextField) {
            onCommit?()
        }
    }

    @Binding var text: String
    var isFirstResponder: Bool
    var placeholder: String = "Field name"
    var shouldResignOnReturn: Bool = true
    var onCommit: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.delegate = context.coordinator
        tf.placeholder = placeholder
        tf.borderStyle = .none
        tf.clearButtonMode = .whileEditing
        tf.returnKeyType = .done
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
        if isFirstResponder, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
        context.coordinator.shouldResignOnReturn = shouldResignOnReturn
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, shouldResignOnReturn: shouldResignOnReturn, onCommit: onCommit)
    }
}
