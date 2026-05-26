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
    @State private var viewport = ViewportState()
    @State private var isShowingSettings = false
    @State private var isShowingGardenLog = false
    @State private var isShowingPayments = false

    var body: some View {
        ZStack {
            HasanaGardenView(
                store: gardenStore,
                viewport: $viewport,
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
                    commandPalette.setPresented(true)
                },
                onReflect: {
                    commandPalette.setPresented(true)
                }
            )
            .environment(\.layoutDirection, .leftToRight)

            CommandPaletteView(viewModel: commandPalette)
        }
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
        .environment(\.layoutDirection, appSettings.layoutDirection)
        .environment(\.locale, appSettings.locale)
        .preferredColorScheme(appSettings.colorScheme)
        .onAppear {
            configureCommandHandlers()
            refreshCommands()
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
                viewport.reset(offset: .zero, scale: 1.0)
                gardenStore.updateViewport(offset: .zero, scale: 1.0)
            }
        case .logWorship:
            gardenStore.selectPractice(nil)
            isShowingGardenLog = true
        case .openPayments:
            isShowingPayments = true
        case .openSettings:
            isShowingSettings = true
        }
    }

    private func refreshCommands() {
        commandPalette.commands = HasanaCommand.defaults(language: appSettings.language)
    }
}

#Preview {
    RootView()
}
