import SwiftUI

struct TodayInputSheet: View {
    let action: TodayAction
    let initialText: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var isFocused: Bool

    init(action: TodayAction, initialText: String = "", onSave: @escaping (String) -> Void) {
        self.action = action
        self.initialText = initialText
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(action.placeholder)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HasanaTheme.textMuted)

                TextEditor(text: $text)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 150)
                    .background(HasanaTheme.elevatedSurfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .focused($isFocused)

                Spacer()
            }
            .padding(18)
            .background(HasanaTheme.background.ignoresSafeArea())
            .navigationTitle(action.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        onSave(text)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
    }
}
