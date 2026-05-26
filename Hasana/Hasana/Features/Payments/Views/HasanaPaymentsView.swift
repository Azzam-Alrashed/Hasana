import SwiftUI

struct HasanaPaymentsView: View {
    let language: HasanaLanguage

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmountID = DonationAmount.defaultID

    private var copy: PaymentsCopy {
        PaymentsCopy(language: language)
    }

    private var selectedAmount: DonationAmount {
        DonationAmount.defaults(language: language).first { $0.id == selectedAmountID } ?? DonationAmount.defaults(language: language)[1]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    DonationHeroCard(copy: copy)

                    DonationAmountPicker(
                        title: copy.amountTitle,
                        selectedAmountID: $selectedAmountID,
                        amounts: DonationAmount.defaults(language: language)
                    )

                    DonationImpactCard(copy: copy)

                    DonationCallToAction(copy: copy, selectedAmount: selectedAmount)
                }
                .padding(16)
            }
            .background(HasanaTheme.background.ignoresSafeArea())
            .navigationTitle(copy.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy.done) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
    }
}

private struct DonationHeroCard: View {
    let copy: PaymentsCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HasanaTheme.gold.opacity(0.2))
                        .frame(width: 68, height: 68)

                    Circle()
                        .stroke(HasanaTheme.gold.opacity(0.36), lineWidth: 1)
                        .frame(width: 52, height: 52)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(HasanaTheme.finance)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(copy.heroEyebrow)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(HasanaTheme.finance)
                        .textCase(.uppercase)

                    Text(copy.heroTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(copy.heroSubtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HasanaTheme.textMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                DonationTrustPill(title: copy.secure, icon: "lock.fill")
                DonationTrustPill(title: copy.developmentLabel, icon: "hammer.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HasanaTheme.elevatedSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.gold.opacity(0.26), lineWidth: 1)
        }
        .shadow(color: HasanaTheme.shadow.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

private struct DonationTrustPill: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(HasanaTheme.finance)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(HasanaTheme.finance.opacity(0.1), in: Capsule())
    }
}

private struct DonationAmountPicker: View {
    let title: String
    @Binding var selectedAmountID: String
    let amounts: [DonationAmount]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(amounts) { amount in
                    Button {
                        selectedAmountID = amount.id
                    } label: {
                        Text(amount.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(selectedAmountID == amount.id ? .white : HasanaTheme.finance)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                selectedAmountID == amount.id ? HasanaTheme.finance : HasanaTheme.elevatedSurfaceSoft,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(selectedAmountID == amount.id ? Color.clear : HasanaTheme.border.opacity(0.58), lineWidth: 0.8)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(HasanaTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.5), lineWidth: 0.8)
        }
    }
}

private struct DonationImpactCard: View {
    let copy: PaymentsCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy.impactTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HasanaTheme.textPrimary)

            ForEach(copy.impactItems) { item in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(item.color.opacity(0.12))

                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(item.color)
                    }
                    .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HasanaTheme.textPrimary)

                        Text(item.subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HasanaTheme.textMuted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(HasanaTheme.elevatedSurfaceSoft.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.5), lineWidth: 0.8)
        }
    }
}

private struct DonationCallToAction: View {
    let copy: PaymentsCopy
    let selectedAmount: DonationAmount

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(copy.readyTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(HasanaTheme.textPrimary)

                    Text(copy.readySubtitle(amount: selectedAmount.title))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HasanaTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text(copy.soonLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HasanaTheme.gold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(HasanaTheme.gold.opacity(0.12), in: Capsule())
            }

            Button {
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .bold))

                    Text(copy.buttonTitle)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(HasanaTheme.finance, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.72)

            Text(copy.noPaymentNotice)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HasanaTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(HasanaTheme.elevatedSurface.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.5), lineWidth: 0.8)
        }
    }
}

private struct DonationAmount: Identifiable {
    static let defaultID = "25"

    let id: String
    let title: String

    static func defaults(language: HasanaLanguage) -> [DonationAmount] {
        switch language {
        case .arabic:
            [
                DonationAmount(id: "10", title: "10 ر.س"),
                DonationAmount(id: "25", title: "25 ر.س"),
                DonationAmount(id: "50", title: "50 ر.س")
            ]
        case .english:
            [
                DonationAmount(id: "10", title: "SAR 10"),
                DonationAmount(id: "25", title: "SAR 25"),
                DonationAmount(id: "50", title: "SAR 50")
            ]
        }
    }
}

private struct DonationImpactItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

private struct PaymentsCopy {
    let language: HasanaLanguage

    var title: String {
        switch language {
        case .arabic:
            "دعم حسنة"
        case .english:
            "Support Hasana"
        }
    }

    var heroEyebrow: String {
        switch language {
        case .arabic:
            "تبرع اختياري"
        case .english:
            "Optional donation"
        }
    }

    var heroTitle: String {
        switch language {
        case .arabic:
            "ساعدنا على بناء حديقة أهدأ وأجمل"
        case .english:
            "Help us build a calmer, better garden"
        }
    }

    var heroSubtitle: String {
        switch language {
        case .arabic:
            "دعمك يذهب لتطوير حسنة وتحسين التجربة، من جمال الحديقة إلى جودة المزايا واستقرار التطبيق."
        case .english:
            "Your support goes into developing Hasana, from garden polish to better features and a more reliable app."
        }
    }

    var secure: String {
        switch language {
        case .arabic:
            "آمن"
        case .english:
            "Secure"
        }
    }

    var developmentLabel: String {
        switch language {
        case .arabic:
            "للتطوير"
        case .english:
            "For development"
        }
    }

    var amountTitle: String {
        switch language {
        case .arabic:
            "اختر مساهمة"
        case .english:
            "Choose a contribution"
        }
    }

    var impactTitle: String {
        switch language {
        case .arabic:
            "ما الذي تدعمه؟"
        case .english:
            "What your support helps with"
        }
    }

    var impactItems: [DonationImpactItem] {
        switch language {
        case .arabic:
            [
                DonationImpactItem(id: "garden", title: "تجربة الحديقة", subtitle: "تحسين الرسوم، الحركة، وشعور النمو اليومي.", icon: "leaf.fill", color: HasanaTheme.accent),
                DonationImpactItem(id: "features", title: "مزايا نافعة", subtitle: "بناء أدوات ألطف للتسجيل، النية، والتأمل.", icon: "sparkles", color: HasanaTheme.gold),
                DonationImpactItem(id: "quality", title: "جودة واستقرار", subtitle: "اختبار أفضل وتجربة أسرع وأكثر ثباتا.", icon: "checkmark.seal.fill", color: HasanaTheme.finance)
            ]
        case .english:
            [
                DonationImpactItem(id: "garden", title: "Garden experience", subtitle: "Better visuals, motion, and daily growth moments.", icon: "leaf.fill", color: HasanaTheme.accent),
                DonationImpactItem(id: "features", title: "Useful features", subtitle: "Gentler tools for logging, intention, and reflection.", icon: "sparkles", color: HasanaTheme.gold),
                DonationImpactItem(id: "quality", title: "Quality and stability", subtitle: "Better testing and a faster, more reliable app.", icon: "checkmark.seal.fill", color: HasanaTheme.finance)
            ]
        }
    }

    var readyTitle: String {
        switch language {
        case .arabic:
            "المساهمة المختارة"
        case .english:
            "Selected contribution"
        }
    }

    func readySubtitle(amount: String) -> String {
        switch language {
        case .arabic:
            "\(amount) عند تفعيل الدفع"
        case .english:
            "\(amount) when donations open"
        }
    }

    var soonLabel: String {
        switch language {
        case .arabic:
            "قريبا"
        case .english:
            "Soon"
        }
    }

    var buttonTitle: String {
        switch language {
        case .arabic:
            "الدفع غير مفعل بعد"
        case .english:
            "Donations are not live yet"
        }
    }

    var noPaymentNotice: String {
        switch language {
        case .arabic:
            "لن يتم تحصيل أي مبلغ من هذه الشاشة الآن."
        case .english:
            "No payment will be collected from this screen right now."
        }
    }

    var done: String {
        switch language {
        case .arabic:
            "تم"
        case .english:
            "Done"
        }
    }
}

#Preview {
    HasanaPaymentsView(language: .english)
}
