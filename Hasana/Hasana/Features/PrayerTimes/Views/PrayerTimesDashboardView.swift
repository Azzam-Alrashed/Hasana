import SwiftUI
import CoreLocation
import Combine

struct PresetLocation: Identifiable, Hashable {
    let id = UUID()
    let nameAr: String
    let nameEn: String
    let latitude: Double
    let longitude: Double
    let timeZoneName: String
    
    func name(for language: HasanaLanguage) -> String {
        language == .arabic ? nameAr : nameEn
    }
    
    static let defaults = [
        PresetLocation(nameAr: "مكة المكرمة", nameEn: "Makkah", latitude: 21.4225, longitude: 39.8262, timeZoneName: "Asia/Riyadh"),
        PresetLocation(nameAr: "المدينة المنورة", nameEn: "Madinah", latitude: 24.4672, longitude: 39.6111, timeZoneName: "Asia/Riyadh"),
        PresetLocation(nameAr: "القاهرة", nameEn: "Cairo", latitude: 30.0444, longitude: 31.2357, timeZoneName: "Africa/Cairo"),
        PresetLocation(nameAr: "دبي", nameEn: "Dubai", latitude: 25.2048, longitude: 55.2708, timeZoneName: "Asia/Dubai"),
        PresetLocation(nameAr: "الرياض", nameEn: "Riyadh", latitude: 24.7136, longitude: 46.6753, timeZoneName: "Asia/Riyadh"),
        PresetLocation(nameAr: "لندن", nameEn: "London", latitude: 51.5074, longitude: -0.1278, timeZoneName: "Europe/London"),
        PresetLocation(nameAr: "نيويورك", nameEn: "New York", latitude: 40.7128, longitude: -74.0060, timeZoneName: "America/New_York"),
        PresetLocation(nameAr: "جاكرتا", nameEn: "Jakarta", latitude: -6.2088, longitude: 106.8456, timeZoneName: "Asia/Jakarta"),
        PresetLocation(nameAr: "كوالالمبور", nameEn: "Kuala Lumpur", latitude: 3.1390, longitude: 101.6869, timeZoneName: "Asia/Kuala_Lumpur")
    ]
}

struct PrayerTimesDashboardView: View {
    let language: HasanaLanguage
    @Binding var settings: PrayerSettings
    
    @State private var times: PrayerTimesEngine.PrayerTimes? = nil
    @State private var currentTime = Date()
    @State private var isShowingConfig = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                HasanaTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Current Countdown Card
                        if let times = times {
                            let next = times.nextPrayer(after: currentTime)
                            let timeUntil = next.time.timeIntervalSince(currentTime)
                            
                            VStack(spacing: 16) {
                                Text(language == .arabic ? "الصلاة القادمة" : "Next Prayer")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textMuted)
                                    .textCase(.uppercase)
                                
                                Text(times.arabicName(for: next.name))
                                    .font(.system(size: 38, weight: .black, design: .rounded))
                                    .foregroundStyle(HasanaTheme.gold)
                                
                                Text(formatTimeInterval(timeUntil))
                                    .font(.system(size: 46, weight: .bold, design: .rounded))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                                    .monospacedDigit()
                                
                                Text("\(language == .arabic ? "في تمام الساعة" : "at") \(formatTime(next.time))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(HasanaTheme.textMuted)
                            }
                            .padding(.vertical, 32)
                            .frame(maxWidth: .infinity)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 1.0)
                            }
                            .shadow(color: HasanaTheme.shadow.opacity(0.12), radius: 20, x: 0, y: 10)
                            .padding(.horizontal)
                            
                            // Times List
                            VStack(spacing: 0) {
                                prayerRow(nameEn: "Fajr", nameAr: "الفجر", icon: "sunrise.fill", time: times.fajr, active: next.name == "Fajr")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                prayerRow(nameEn: "Sunrise", nameAr: "الشروق", icon: "sun.max.fill", time: times.sunrise, active: next.name == "Sunrise")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                prayerRow(nameEn: "Dhuhr", nameAr: "الظهر", icon: "sun.min.fill", time: times.dhuhr, active: next.name == "Dhuhr")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                prayerRow(nameEn: "Asr", nameAr: "العصر", icon: "sun.haze.fill", time: times.asr, active: next.name == "Asr")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                prayerRow(nameEn: "Maghrib", nameAr: "المغرب", icon: "sunset.fill", time: times.maghrib, active: next.name == "Maghrib")
                                Divider().background(HasanaTheme.border.opacity(0.24))
                                prayerRow(nameEn: "Isha", nameAr: "العشاء", icon: "moon.stars.fill", time: times.isha, active: next.name == "Isha")
                            }
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(HasanaTheme.border.opacity(0.48), lineWidth: 0.8)
                            }
                            .padding(.horizontal)
                        } else {
                            ProgressView()
                                .padding(.top, 64)
                        }
                        
                        // Location Info card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language == .arabic ? "الموقع الحالي" : "Current Location")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textMuted)
                                
                                Text(settings.cityName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(HasanaTheme.textPrimary)
                            }
                            
                            Spacer()
                            
                            Button {
                                isShowingConfig = true
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(HasanaTheme.accent, in: Capsule())
                            }
                        }
                        .padding()
                        .background(HasanaTheme.elevatedSurface.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(HasanaTheme.border.opacity(0.44), lineWidth: 0.8)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(language == .arabic ? "مواقيت الصلاة" : "Prayer Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .arabic ? "تم" : "Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isShowingConfig) {
                PrayerConfigSheet(settings: $settings, language: language) {
                    recalculate()
                }
            }
            .onAppear {
                recalculate()
            }
            .onReceive(timer) { input in
                currentTime = input
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    
    private func recalculate() {
        let timezone = TimeZone(identifier: TimeZone.current.identifier) ?? TimeZone.current
        let offset = Double(timezone.secondsFromGMT(for: Date())) / 3600.0
        
        times = PrayerTimesEngine.calculateTimes(
            for: Date(),
            latitude: settings.latitude,
            longitude: settings.longitude,
            timeZoneOffset: offset,
            method: settings.method,
            useHanafiAsr: settings.useHanafiAsr
        )
    }
    
    private func prayerRow(nameEn: String, nameAr: String, icon: String, time: Date, active: Bool) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(active ? HasanaTheme.gold : HasanaTheme.accent)
                    .frame(width: 24)
                
                Text(language == .arabic ? nameAr : nameEn)
                    .font(.system(size: 16, weight: active ? .bold : .medium))
                    .foregroundStyle(active ? HasanaTheme.textPrimary : HasanaTheme.textPrimary.opacity(0.85))
            }
            
            Spacer()
            
            Text(formatTime(time))
                .font(.system(size: 16, weight: active ? .bold : .semibold, design: .rounded))
                .foregroundStyle(active ? HasanaTheme.gold : HasanaTheme.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(active ? HasanaTheme.accentSoft.opacity(0.58) : Color.clear)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "00:00:00" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct PrayerConfigSheet: View {
    @Binding var settings: PrayerSettings
    let language: HasanaLanguage
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(language == .arabic ? "طريقة الحساب" : "Calculation Method")) {
                    Picker(language == .arabic ? "الجهة" : "Authority", selection: $settings.method) {
                        ForEach(CalculationMethod.allCases) { method in
                            Text(method.title(for: language)).tag(method)
                        }
                    }
                    
                    Toggle(language == .arabic ? "المذهب الحنفي للعصر" : "Hanafi Asr Shadow Rule", isOn: $settings.useHanafiAsr)
                }
                
                Section(header: Text(language == .arabic ? "المدينة والموقع" : "City & Coordinates")) {
                    Picker(language == .arabic ? "اختر مدينة" : "Select Preset City", selection: Binding(
                        get: {
                            PresetLocation.defaults.first { abs($0.latitude - settings.latitude) < 0.01 && abs($0.longitude - settings.longitude) < 0.01 } ?? PresetLocation.defaults[0]
                        },
                        set: { preset in
                            settings.latitude = preset.latitude
                            settings.longitude = preset.longitude
                            settings.cityName = preset.name(for: language)
                        }
                    )) {
                        ForEach(PresetLocation.defaults) { preset in
                            Text(preset.name(for: language)).tag(preset)
                        }
                    }
                    
                    HStack {
                        Text(language == .arabic ? "خط العرض" : "Latitude")
                        Spacer()
                        Text(String(format: "%.4f", settings.latitude))
                            .foregroundStyle(HasanaTheme.textMuted)
                    }
                    
                    HStack {
                        Text(language == .arabic ? "خط الطول" : "Longitude")
                        Spacer()
                        Text(String(format: "%.4f", settings.longitude))
                            .foregroundStyle(HasanaTheme.textMuted)
                    }
                }
                
                Section(header: Text(language == .arabic ? "التنبيهات والأذان" : "Notifications & Athan")) {
                    Toggle(language == .arabic ? "تفعيل تنبيهات الأذان" : "Enable Athan Alarms", isOn: $settings.enableAthanNotifications)
                }
            }
            .navigationTitle(language == .arabic ? "إعدادات الصلاة" : "Calculation Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .arabic ? "حفظ" : "Save") {
                        onSave()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }
}
