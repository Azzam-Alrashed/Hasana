//
//  RootView.swift
//  Hasana
//
//  Created by Azzam Alrashed on 25/05/2026.
//

import SwiftUI

struct RootView: View {
    @State private var commandPalette = CommandPaletteViewModel()
    @State private var dailyStore = HasanaDailyStore()
    @State private var locationService = HasanaPrayerLocationService()
    @State private var reminderService = HasanaReminderService()
    @State private var activeAction: TodayAction?

    private var prayerSchedule: HasanaPrayerSchedule {
        HasanaPrayerTimeCalculator.schedule(
            for: .now,
            coordinate: locationService.coordinate,
            countryCode: locationService.countryCode
        )
    }

    var body: some View {
        ZStack {
            TodayDashboardView(
                dailyStore: dailyStore,
                locationService: locationService,
                reminderService: reminderService,
                prayerSchedule: prayerSchedule,
                onAction: present
            )

            FloatingCommandButton(
                onTap: {
                    commandPalette.setPresented(true)
                },
                onLogGoodDeed: {
                    present(.logGoodDeed)
                },
                onSetIntention: {
                    present(.setIntention)
                },
                onReflect: {
                    present(.reflect)
                }
            )

            CommandPaletteView(viewModel: commandPalette)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .sheet(item: $activeAction) { action in
            TodayInputSheet(action: action, initialText: initialText(for: action)) { value in
                commit(value, for: action)
            }
            .presentationDetents([.height(310), .medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            dailyStore.refreshForToday()
            reminderService.refreshAuthorizationStatus()
            configureCommandHandlers()
        }
    }

    private func configureCommandHandlers() {
        commandPalette.onExecute = { commandID in
            handle(commandID)
        }

        commandPalette.onSubmitPrompt = { prompt in
            dailyStore.addPriority(prompt)
        }
    }

    private func handle(_ commandID: HasanaCommandID) {
        switch commandID {
        case .openToday:
            dailyStore.refreshForToday()
        case .logGoodDeed:
            present(.logGoodDeed)
        case .setIntention:
            present(.setIntention)
        case .addPriority:
            present(.addPriority)
        case .openPrayerTimes:
            locationService.requestLocation()
        case .startDhikr:
            dailyStore.incrementDhikr()
        case .reflect:
            present(.reflect)
        case .addSadaqah:
            present(.addSadaqah)
        }
    }

    private func present(_ action: TodayAction) {
        activeAction = action
    }

    private func initialText(for action: TodayAction) -> String {
        switch action {
        case .setIntention:
            dailyStore.record.intention
        case .reflect:
            dailyStore.record.reflection
        case .addPriority, .logGoodDeed, .addSadaqah:
            ""
        }
    }

    private func commit(_ value: String, for action: TodayAction) {
        switch action {
        case .setIntention:
            dailyStore.updateIntention(value)
        case .addPriority:
            dailyStore.addPriority(value)
        case .logGoodDeed:
            dailyStore.addGoodDeed(value)
        case .addSadaqah:
            dailyStore.addSadaqahNote(value)
        case .reflect:
            dailyStore.updateReflection(value)
        }
    }
}

#Preview {
    RootView()
}
