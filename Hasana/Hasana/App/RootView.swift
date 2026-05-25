//
//  RootView.swift
//  Hasana
//
//  Created by Azzam Alrashed on 25/05/2026.
//

import SwiftUI

struct RootView: View {
    @State private var commandPalette = CommandPaletteViewModel()
    @State private var canvasStore = HasanaCanvasStore()
    @State private var appSettings = HasanaAppSettings()
    @State private var viewport = ViewportState()
    @State private var isShowingSettings = false

    var body: some View {
        ZStack {
            HasanaCanvasView(
                store: canvasStore,
                viewport: $viewport,
                onNodeAction: { commandID in
                    handle(commandID)
                }
            )

            FloatingCommandButton(
                onTap: {
                    commandPalette.setPresented(true)
                },
                onLogGoodDeed: {
                    handle(.clearCanvas)
                },
                onSetIntention: {
                    handle(.resetView)
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

        commandPalette.onSubmitPrompt = { prompt in
            withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                let _ = canvasStore.addIdea(prompt: prompt, viewport: viewport)
            }
        }
    }

    private func handle(_ commandID: HasanaCommandID) {
        switch commandID {
        case .resetView:
            withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                viewport.reset(offset: .zero, scale: 1.0)
                canvasStore.updateViewport(offset: .zero, scale: 1.0)
            }
        case .clearCanvas:
            withAnimation(.spring()) {
                canvasStore.clearCanvas()
            }
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
