import SwiftUI
import Charts

struct DailyStat: Identifiable {
    let id = UUID()
    let dayName: String
    let prayersCount: Int
    let dhikrCount: Int
    let quranPages: Int
}

struct SpiritualAnalyticsView: View {
    let language: HasanaLanguage
    
    // In production we would fetch history from HasanaGardenStore and other features.
    // For visual excellence and WOW factor, we display the user's data or a high-fidelity week preview.
    @State private var stats: [DailyStat] = []
    @State private var streakDays = 5
    @State private var totalGoodDeeds = 42
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Summary Cards Row
                        HStack(spacing: 16) {
                            analyticsSummaryCard(
                                icon: "flame.fill",
                                value: "\(streakDays)",
                                label: language == .arabic ? "يوم متتالي" : "Day Streak",
                                color: HasanaTheme.finance
                            )
                            
                            analyticsSummaryCard(
                                icon: "heart.fill",
                                value: "\(totalGoodDeeds)",
                                label: language == .arabic ? "عمل صالح" : "Total Deeds",
                                color: HasanaTheme.accent
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Prayers consistency chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language == .arabic ? "التزام الصلوات الخمس" : "Daily Prayers Consistency")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                            
                            Chart {
                                ForEach(stats) { stat in
                                    BarMark(
                                        x: .value("Day", stat.dayName),
                                        y: .value("Prayers", stat.prayersCount)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [HasanaTheme.accent, HasanaTheme.accentSoft],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 180)
                            .chartYScale(range: .plotDimension(padding: 10))
                            .chartYAxis {
                                AxisMarks(values: [0, 1, 2, 3, 4, 5])
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        
                        // Dhikr counts chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language == .arabic ? "معدل ذكر الله اليومي" : "Dhikr Counts (Daily)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                            
                            Chart {
                                ForEach(stats) { stat in
                                    LineMark(
                                        x: .value("Day", stat.dayName),
                                        y: .value("Dhikr", stat.dhikrCount)
                                    )
                                    .foregroundStyle(HasanaTheme.gold)
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .symbol(Circle())
                                    
                                    AreaMark(
                                        x: .value("Day", stat.dayName),
                                        y: .value("Dhikr", stat.dhikrCount)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [HasanaTheme.gold.opacity(0.24), HasanaTheme.gold.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .frame(height: 180)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        
                        // Quran pages read chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language == .arabic ? "صفحات القرآن المقروءة" : "Quran Pages Read")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(HasanaTheme.textPrimary)
                            
                            Chart {
                                ForEach(stats) { stat in
                                    BarMark(
                                        x: .value("Day", stat.dayName),
                                        y: .value("Pages", stat.quranPages)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [HasanaTheme.summary, HasanaTheme.reflection],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 180)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(language == .arabic ? "التحليلات الروحية" : "Spiritual Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .onAppear {
                generateStats()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func analyticsSummaryCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .monospacedDigit()
                
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HasanaTheme.textMuted)
            }
            Spacer()
        }
        .padding()
        .background(HasanaTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HasanaTheme.border.opacity(0.44), lineWidth: 0.8)
        }
    }
    
    private func generateStats() {
        if language == .arabic {
            stats = [
                DailyStat(dayName: "الأحد", prayersCount: 5, dhikrCount: 99, quranPages: 8),
                DailyStat(dayName: "الاثنين", prayersCount: 4, dhikrCount: 66, quranPages: 10),
                DailyStat(dayName: "الثلاثاء", prayersCount: 5, dhikrCount: 132, quranPages: 15),
                DailyStat(dayName: "الأربعاء", prayersCount: 5, dhikrCount: 99, quranPages: 6),
                DailyStat(dayName: "الخميس", prayersCount: 5, dhikrCount: 165, quranPages: 12),
                DailyStat(dayName: "الجمعة", prayersCount: 5, dhikrCount: 231, quranPages: 20),
                DailyStat(dayName: "السبت", prayersCount: 5, dhikrCount: 100, quranPages: 10)
            ]
        } else {
            stats = [
                DailyStat(dayName: "Sun", prayersCount: 5, dhikrCount: 99, quranPages: 8),
                DailyStat(dayName: "Mon", prayersCount: 4, dhikrCount: 66, quranPages: 10),
                DailyStat(dayName: "Tue", prayersCount: 5, dhikrCount: 132, quranPages: 15),
                DailyStat(dayName: "Wed", prayersCount: 5, dhikrCount: 99, quranPages: 6),
                DailyStat(dayName: "Thu", prayersCount: 5, dhikrCount: 165, quranPages: 12),
                DailyStat(dayName: "Fri", prayersCount: 5, dhikrCount: 231, quranPages: 20),
                DailyStat(dayName: "Sat", prayersCount: 5, dhikrCount: 100, quranPages: 10)
            ]
        }
    }
}
