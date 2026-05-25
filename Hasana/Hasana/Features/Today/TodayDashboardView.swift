import SwiftUI
import UserNotifications

struct TodayDashboardView: View {
    @Bindable var dailyStore: HasanaDailyStore
    @Bindable var locationService: HasanaPrayerLocationService
    @Bindable var reminderService: HasanaReminderService

    let prayerSchedule: HasanaPrayerSchedule
    let onAction: (TodayAction) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    PrayerOverviewCard(
                        dailyStore: dailyStore,
                        locationService: locationService,
                        schedule: prayerSchedule
                    )
                    intentionCard
                    quickStats
                    prioritiesCard
                    journalGrid
                    reflectionCard
                    settingsCard
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(HasanaTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("حسنة")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)

                Text("نظام يومي هادئ للمسلم المهني")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HasanaTheme.accent)

                Text(Date.now, format: .dateTime.day().month(.wide))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
            }
            .padding(10)
            .background(HasanaTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var intentionCard: some View {
        HasanaSectionCard(icon: "sparkles", title: "نية اليوم", tint: HasanaTheme.reflection) {
            VStack(alignment: .leading, spacing: 10) {
                if dailyStore.record.intention.isEmpty {
                    Text("اكتب نية قصيرة تجعل عملك ووقتك أقرب للخير.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HasanaTheme.textMuted)
                } else {
                    Text(dailyStore.record.intention)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    onAction(.setIntention)
                } label: {
                    Label(dailyStore.record.intention.isEmpty ? "تحديد النية" : "تعديل النية", systemImage: "square.and.pencil")
                }
                .buttonStyle(HasanaPrimaryButtonStyle())
            }
        }
    }

    private var quickStats: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            MetricTile(
                title: "الذكر",
                value: "\(dailyStore.record.dhikrCount)",
                icon: "circle.grid.cross",
                tint: HasanaTheme.accent
            ) {
                dailyStore.incrementDhikr()
            }

            MetricTile(
                title: "الصلوات",
                value: "\(dailyStore.record.completedPrayers.count)/5",
                icon: "checkmark.seal",
                tint: HasanaTheme.gold
            ) {
                if let next = prayerSchedule.nextPrayer() {
                    dailyStore.togglePrayer(next.name)
                }
            }
        }
    }

    private var prioritiesCard: some View {
        HasanaSectionCard(icon: "checkmark.circle", title: "أولويات العمل", tint: HasanaTheme.idea) {
            VStack(spacing: 10) {
                if dailyStore.record.priorities.isEmpty {
                    EmptyLine(text: "أضف أهم ما يستحق تركيزك اليوم.")
                } else {
                    ForEach(dailyStore.record.priorities) { priority in
                        Button {
                            dailyStore.togglePriority(priority)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: priority.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(priority.isDone ? HasanaTheme.accent : HasanaTheme.textMuted)

                                Text(priority.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .strikethrough(priority.isDone, color: HasanaTheme.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(2)
                            }
                            .padding(10)
                            .background(HasanaTheme.elevatedSurfaceSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    onAction(.addPriority)
                } label: {
                    Label("إضافة أولوية", systemImage: "plus")
                }
                .buttonStyle(HasanaSecondaryButtonStyle())
            }
        }
    }

    private var journalGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            JournalCard(
                title: "حسنة اليوم",
                emptyText: "احفظ موقفاً طيباً قبل أن يمر.",
                entries: dailyStore.record.goodDeeds,
                icon: "heart.fill",
                tint: HasanaTheme.accent
            ) {
                onAction(.logGoodDeed)
            }

            JournalCard(
                title: "صدقة",
                emptyText: "سجل عطاءً أو نية عطاء.",
                entries: dailyStore.record.sadaqahNotes,
                icon: "creditcard",
                tint: HasanaTheme.finance
            ) {
                onAction(.addSadaqah)
            }
        }
    }

    private var reflectionCard: some View {
        HasanaSectionCard(icon: "moon.stars", title: "مراجعة المساء", tint: HasanaTheme.reflection) {
            VStack(alignment: .leading, spacing: 10) {
                if dailyStore.record.reflection.isEmpty {
                    EmptyLine(text: "اختم يومك بجملة رحيمة: ماذا تعلمت؟")
                } else {
                    Text(dailyStore.record.reflection)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    onAction(.reflect)
                } label: {
                    Label("كتابة المراجعة", systemImage: "pencil.and.outline")
                }
                .buttonStyle(HasanaSecondaryButtonStyle())
            }
        }
    }

    private var settingsCard: some View {
        HasanaSectionCard(icon: "bell.badge", title: "الخصوصية والتذكيرات", tint: HasanaTheme.gold) {
            VStack(alignment: .leading, spacing: 12) {
                Text("بياناتك محفوظة على جهازك فقط. لا يوجد حساب أو مزامنة في هذه النسخة.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Text(reminderService.message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)

                HStack(spacing: 10) {
                    Button {
                        reminderService.requestAuthorizationAndSchedule(prayerSchedule: prayerSchedule)
                    } label: {
                        Label("تفعيل التذكيرات", systemImage: "bell")
                    }
                    .buttonStyle(HasanaPrimaryButtonStyle())

                    Button {
                        locationService.requestLocation()
                    } label: {
                        Label("تحديث الموقع", systemImage: "location")
                    }
                    .buttonStyle(HasanaSecondaryButtonStyle())
                }
            }
        }
    }
}

struct PrayerOverviewCard: View {
    @Bindable var dailyStore: HasanaDailyStore
    @Bindable var locationService: HasanaPrayerLocationService

    let schedule: HasanaPrayerSchedule

    private var nextPrayer: HasanaPrayerTime? {
        schedule.nextPrayer() ?? schedule.prayers.first(where: { $0.name.isPrayer })
    }

    var body: some View {
        HasanaSectionCard(icon: "clock", title: "الصلاة", tint: HasanaTheme.accent) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("الصلاة القادمة")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(HasanaTheme.textMuted)

                        Text(nextPrayer?.name.arabicTitle ?? "الفجر")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(HasanaTheme.textPrimary)
                    }

                    Spacer()

                    Text(nextPrayer?.date ?? .now, format: .dateTime.hour().minute())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(HasanaTheme.accent)
                        .monospacedDigit()
                }

                Text("\(locationService.locationMessage) • \(schedule.method.arabicTitle)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)

                VStack(spacing: 8) {
                    ForEach(schedule.prayers) { prayer in
                        PrayerRow(
                            prayer: prayer,
                            isComplete: dailyStore.record.completedPrayers.contains(prayer.name)
                        ) {
                            dailyStore.togglePrayer(prayer.name)
                        }
                    }
                }
            }
        }
    }
}

private struct PrayerRow: View {
    let prayer: HasanaPrayerTime
    let isComplete: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : (prayer.name.isPrayer ? "circle" : "sunrise"))
                    .foregroundStyle(isComplete ? HasanaTheme.accent : HasanaTheme.textMuted)
                    .frame(width: 22)

                Text(prayer.name.arabicTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)

                Spacer()

                Text(prayer.date, format: .dateTime.hour().minute())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(HasanaTheme.elevatedSurfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!prayer.name.isPrayer)
    }
}

private struct JournalCard: View {
    let title: String
    let emptyText: String
    let entries: [HasanaJournalEntry]
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        HasanaSectionCard(icon: icon, title: title, tint: tint) {
            VStack(alignment: .leading, spacing: 10) {
                if let entry = entries.first {
                    Text(entry.text)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(entries.count) محفوظة اليوم")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tint)
                } else {
                    EmptyLine(text: emptyText)
                }

                Button(action: action) {
                    Label("إضافة", systemImage: "plus")
                }
                .buttonStyle(HasanaSecondaryButtonStyle())
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(HasanaTheme.textMuted)

                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(HasanaTheme.textPrimary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(HasanaTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(HasanaTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HasanaSectionCard<Content: View>: View {
    let icon: String
    let title: String
    let tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(HasanaTheme.textPrimary)

                Spacer()
            }

            content
        }
        .padding(14)
        .background(HasanaTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HasanaTheme.border, lineWidth: 1)
        )
        .shadow(color: HasanaTheme.shadow.opacity(0.07), radius: 14, x: 0, y: 8)
    }
}

private struct EmptyLine: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(HasanaTheme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct HasanaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(HasanaTheme.accent.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }
}

struct HasanaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(HasanaTheme.accent)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(HasanaTheme.accentSoft.opacity(configuration.isPressed ? 0.62 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }
}

enum TodayAction: Identifiable {
    case setIntention
    case addPriority
    case logGoodDeed
    case addSadaqah
    case reflect

    var id: String {
        switch self {
        case .setIntention:
            "setIntention"
        case .addPriority:
            "addPriority"
        case .logGoodDeed:
            "logGoodDeed"
        case .addSadaqah:
            "addSadaqah"
        case .reflect:
            "reflect"
        }
    }

    var title: String {
        switch self {
        case .setIntention:
            "نية اليوم"
        case .addPriority:
            "أولوية جديدة"
        case .logGoodDeed:
            "تسجيل حسنة"
        case .addSadaqah:
            "تسجيل صدقة"
        case .reflect:
            "مراجعة المساء"
        }
    }

    var placeholder: String {
        switch self {
        case .setIntention:
            "أنوي أن يكون عملي اليوم نافعاً..."
        case .addPriority:
            "ما أهم أولوية اليوم؟"
        case .logGoodDeed:
            "اكتب الحسنة باختصار"
        case .addSadaqah:
            "صدقة أو نية عطاء"
        case .reflect:
            "ماذا تعلمت اليوم؟"
        }
    }
}

#Preview {
    TodayDashboardView(
        dailyStore: HasanaDailyStore(),
        locationService: HasanaPrayerLocationService(),
        reminderService: HasanaReminderService(),
        prayerSchedule: HasanaPrayerTimeCalculator.schedule(
            for: .now,
            coordinate: .riyadh,
            countryCode: "SA"
        ),
        onAction: { _ in }
    )
}
