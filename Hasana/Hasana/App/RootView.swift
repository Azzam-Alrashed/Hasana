//
//  RootView.swift
//  Hasana
//
//  Created by Azzam Alrashed on 25/05/2026.
//

import SwiftUI

struct RootView: View {
    @State private var commandPalette = CommandPaletteViewModel()
    @State private var gardenStore = HasanaGardenStore()
    @State private var appSettings = HasanaAppSettings()
    @State private var gardenCamera = HasanaGardenCameraState()
    @State private var isShowingSettings = false
    @State private var isShowingGardenLog = false
    @State private var isShowingPayments = false
    @State private var isShowingPrayerDashboard = false
    @State private var isShowingTasbih = false
    @State private var isShowingQuranTracker = false
    @State private var isShowingSunnahTracker = false
    @State private var isShowingAnalytics = false
    @State private var isShowingIslamicHub = false
    @State private var prayerSettings: PrayerSettings = {
        if let data = UserDefaults.standard.data(forKey: "hasana.prayer.settings"),
           let decoded = try? JSONDecoder().decode(PrayerSettings.self, from: data) {
            return decoded
        }
        return PrayerSettings()
    }()

    var body: some View {
        ZStack {
            HasanaGardenView(
                store: gardenStore,
                cameraState: gardenCamera,
                language: appSettings.language,
                onPracticeSelected: { practiceID in
                    gardenStore.selectPractice(practiceID)
                    isShowingGardenLog = true
                }
            )

            FloatingCommandButton(
                onTap: {
                    commandPalette.setPresented(true)
                },
                onLogGoodDeed: {
                    gardenStore.selectPractice(nil)
                    isShowingGardenLog = true
                },
                onSetIntention: {
                    commandPalette.query = appSettings.language == .arabic ? "الإعدادات" : "Settings"
                    commandPalette.setPresented(true)
                },
                onReflect: {
                    commandPalette.query = appSettings.language == .arabic ? "تسجيل" : "Log"
                    commandPalette.setPresented(true)
                }
            )
            .environment(\.layoutDirection, .leftToRight)

            CommandPaletteView(viewModel: commandPalette)
        }
        .id(appSettings.theme)
        .sheet(isPresented: $isShowingSettings) {
            HasanaSettingsView(settings: appSettings)
        }
        .sheet(isPresented: $isShowingPayments) {
            HasanaPaymentsView(language: appSettings.language)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingGardenLog) {
            HasanaGardenLogSheet(
                store: gardenStore,
                language: appSettings.language
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingPrayerDashboard) {
            PrayerTimesDashboardView(language: appSettings.language, settings: $prayerSettings)
        }
        .sheet(isPresented: $isShowingTasbih) {
            HasanaTasbihView(language: appSettings.language, onLoggedAdhkar: {
                withAnimation {
                    gardenStore.toggleToday(for: .adhkar)
                }
            })
        }
        .sheet(isPresented: $isShowingQuranTracker) {
            QuranJournalView(language: appSettings.language, onLoggedQuran: {
                withAnimation {
                    gardenStore.toggleToday(for: .quran)
                }
            })
        }
        .sheet(isPresented: $isShowingSunnahTracker) {
            SunnahTrackerView(language: appSettings.language, selectedDayKey: gardenStore.selectedDayKey, onLoggedSunnah: {
                withAnimation {
                    gardenStore.toggleToday(for: .witr)
                }
            })
        }
        .sheet(isPresented: $isShowingAnalytics) {
            SpiritualAnalyticsView(language: appSettings.language)
        }
        .sheet(isPresented: $isShowingIslamicHub) {
            IslamicHubView(language: appSettings.language, selectedDayKey: gardenStore.selectedDayKey, onLoggedWorship: { practiceID in
                withAnimation {
                    if let practice = HasanaGardenPracticeID(rawValue: practiceID) {
                        gardenStore.toggleToday(for: practice)
                    }
                }
            })
        }
        .onChange(of: prayerSettings) { _, newValue in
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "hasana.prayer.settings")
            }
            rescheduleAthanNotifications()
        }
        .environment(\.layoutDirection, appSettings.layoutDirection)
        .environment(\.locale, appSettings.locale)
        .preferredColorScheme(appSettings.colorScheme)
        .onAppear {
            configureCommandHandlers()
            refreshCommands()
            
            // Audio setup
            SoundManager.shared.playAmbientSound()
            
            // Notification Auth and schedule
            NotificationManager.shared.requestAuthorization()
            rescheduleAthanNotifications()
        }
        .onChange(of: appSettings.language) {
            refreshCommands()
        }
    }

    private func configureCommandHandlers() {
        commandPalette.onExecute = { commandID in
            handle(commandID)
        }
        commandPalette.onSubmitPrompt = nil
    }

    private func handle(_ commandID: HasanaCommandID) {
        switch commandID {
        case .resetView:
            withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                gardenCamera.reset()
            }
        case .logWorship:
            gardenStore.selectPractice(nil)
            isShowingGardenLog = true
        case .openPayments:
            isShowingPayments = true
        case .openSettings:
            isShowingSettings = true
        case .openTasbih:
            isShowingTasbih = true
        case .openQuranTracker:
            isShowingQuranTracker = true
        case .openSunnahTracker:
            isShowingSunnahTracker = true
        case .openAnalytics:
            isShowingAnalytics = true
        case .openPrayerDashboard:
            isShowingPrayerDashboard = true
        case .openIslamicHub:
            isShowingIslamicHub = true
        }
    }

    private func rescheduleAthanNotifications() {
        let timezone = TimeZone(identifier: TimeZone.current.identifier) ?? TimeZone.current
        let offset = Double(timezone.secondsFromGMT(for: Date())) / 3600.0
        
        let calculated = PrayerTimesEngine.calculateTimes(
            for: Date(),
            latitude: prayerSettings.latitude,
            longitude: prayerSettings.longitude,
            timeZoneOffset: offset,
            method: prayerSettings.method,
            useHanafiAsr: prayerSettings.useHanafiAsr
        )
        
        NotificationManager.shared.scheduleAthanNotifications(
            for: calculated,
            settings: prayerSettings,
            language: appSettings.language
        )
    }

    private func refreshCommands() {
        commandPalette.commands = HasanaCommand.defaults(language: appSettings.language)
    }
}

#Preview {
    RootView()
}
