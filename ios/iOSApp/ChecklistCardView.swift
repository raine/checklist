import SwiftUI

struct ChecklistCardView: View {
    let list: Checklist
    let itemSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(list.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.tileText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Item preview
            let previewItems = Array(list.fields.prefix(5))
            ForEach(previewItems) { field in
                HStack(spacing: 6) {
                    Image(systemName: field.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.tileText.opacity(field.isChecked ? 1 : 0.35))
                    Text(field.name)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.tileText.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Progress count
            let total = list.fields.count
            let done = list.fields.count(where: { $0.isChecked })
            Text("\(done)/\(total)")
                .foregroundColor(AppTheme.tileText.opacity(0.5))
                .font(.caption)
        }
        .padding(12)
        .frame(width: itemSize, height: itemSize, alignment: .topLeading)
        .background(AppTheme.tileBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.primary.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
