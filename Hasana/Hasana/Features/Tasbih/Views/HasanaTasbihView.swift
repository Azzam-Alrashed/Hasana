import SwiftUI
import UIKit

struct HasanaTasbihView: View {
    let language: HasanaLanguage
    let onLoggedAdhkar: () -> Void
    
    @State private var presets = DhikrPreset.defaults
    @State private var selectedPresetIndex = 0
    @State private var counter = 0
    @State private var sessionsCompleted = 0
    @State private var totalCounts = 0
    @State private var scale: CGFloat = 1.0
    @State private var isShowingCustomDhikr = false
    @State private var customDhikrAr = ""
    @State private var customDhikrEn = ""
    @State private var customLimit = 33
    
    @Environment(\.dismiss) private var dismiss
    
    private var activeDhikr: DhikrPreset {
        presets[selectedPresetIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Top Session Display
                    HStack(spacing: 16) {
                        statusBadge(
                            icon: "number",
                            value: "\(totalCounts)",
                            label: language == .arabic ? "إجمالي التكرار" : "Total counts"
                        )
                        
                        statusBadge(
                            icon: "leaf.fill",
                            value: "\(sessionsCompleted)",
                            label: language == .arabic ? "أوراد منجزة" : "Finished sets"
                        )
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // Preset Carousel
                    VStack(spacing: 8) {
                        HStack {
                            Button {
                                changePreset(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .bold()
                                    .foregroundStyle(HasanaTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Text(activeDhikr.name(for: language))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(HasanaTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(height: 60)
                                .id(activeDhikr.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            
                            Spacer()
                            
                            Button {
                                changePreset(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .bold()
                                    .foregroundStyle(HasanaTheme.textMuted)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Text("\(counter) / \(activeDhikr.defaultLimit)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HasanaTheme.gold)
                    }
                    
                    Spacer()
                    
                    // The Tasbih Massive Button
                    Button {
                        incrementCounter()
                    } label: {
                        ZStack {
                            // Pulsing Ring Shadow
                            Circle()
                                .stroke(HasanaTheme.accent.opacity(0.18), lineWidth: 16)
                                .scaleEffect(scale)
                            
                            // Progress Circle
                            Circle()
                                .trim(from: 0.0, to: CGFloat(counter) / CGFloat(activeDhikr.defaultLimit))
                                .stroke(
                                    LinearGradient(
                                        colors: [HasanaTheme.accent, HasanaTheme.gold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.28, dampingFraction: 0.76), value: counter)
                            
                            // Dial Body
                            Circle()
                                .fill(HasanaTheme.elevatedSurface.opacity(0.88))
                                .shadow(color: HasanaTheme.accent.opacity(0.24), radius: 24, x: 0, y: 12)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "hand.tap")
                                    .font(.system(size: 28))
                                    .foregroundStyle(HasanaTheme.accent)
                                
                                Text("\(counter)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .monospacedDigit()
                                
                                Text(language == .arabic ? "اضغط" : "TAP")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textMuted)
                                    .tracking(1.4)
                            }
                        }
                        .frame(width: 240, height: 240)
                        .scaleEffect(scale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Reset and Custom Buttons
                    HStack(spacing: 20) {
                        Button {
                            triggerHapticFeedback(.medium)
                            withAnimation {
                                counter = 0
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text(language == .arabic ? "تصفير" : "Reset")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HasanaTheme.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay {
                                Capsule().stroke(HasanaTheme.border.opacity(0.54), lineWidth: 0.8)
                            }
                        }
                        
                        Button {
                            isShowingCustomDhikr = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                Text(language == .arabic ? "ذكر مخصص" : "Custom Dhikr")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(HasanaTheme.accent, in: Capsule())
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(language == .arabic ? "المسبحة الإلكترونية" : "Tasbih Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "إغلاق" : "Close") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $isShowingCustomDhikr) {
                customDhikrSheet
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func statusBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(HasanaTheme.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .textCase(.uppercase)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(HasanaTheme.elevatedSurface.opacity(0.68), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.44), lineWidth: 0.8)
        }
    }
    
    private func changePreset(by amount: Int) {
        triggerHapticFeedback(.light)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            selectedPresetIndex = (selectedPresetIndex + amount + presets.count) % presets.count
            counter = 0
        }
    }
    
    private func incrementCounter() {
        // Micro-haptic on every tap
        triggerHapticFeedback(.light)
        
        withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
            scale = 0.94
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
        
        counter += 1
        totalCounts += 1
        
        if counter >= activeDhikr.defaultLimit {
            // Target achieved celebration!
            triggerHapticFeedback(.heavy)
            sessionsCompleted += 1
            counter = 0
            
            // Log/Tend Adhkar in the Garden!
            onLoggedAdhkar()
        }
    }
    
    private var customDhikrSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "الذكر الجديد" : "New Dhikr")) {
                    TextField(language == .arabic ? "الذكر بالعربية" : "Dhikr in Arabic", text: $customDhikrAr)
                        .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    TextField(language == .arabic ? "الذكر بالإنجليزية" : "Dhikr in English", text: $customDhikrEn)
                    
                    Stepper(value: $customLimit, in: 1...1000) {
                        Text("\(language == .arabic ? "العدد المطلوب:" : "Target Limit:") \(customLimit)")
                    }
                }
            }
            .navigationTitle(language == .arabic ? "إضافة ذكر" : "Add Custom Dhikr")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "إلغاء" : "Cancel") {
                        isShowingCustomDhikr = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "حفظ" : "Save") {
                        if !customDhikrAr.isEmpty && !customDhikrEn.isEmpty {
                            let newPreset = DhikrPreset(
                                arabicName: customDhikrAr,
                                englishName: customDhikrEn,
                                defaultLimit: customLimit
                            )
                            presets.append(newPreset)
                            selectedPresetIndex = presets.count - 1
                            counter = 0
                            isShowingCustomDhikr = false
                            
                            // Reset input
                            customDhikrAr = ""
                            customDhikrEn = ""
                            customLimit = 33
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
