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
    @State private var viewport = ViewportState()

    var body: some View {
        ZStack {
            // Main Spatial Canvas View
            HasanaCanvasView(
                store: canvasStore,
                viewport: $viewport,
                onNodeAction: { commandID in
                    handle(commandID)
                }
            )

            // Floating Command (Overlay)
            FloatingCommandButton(
                onTap: {
                    commandPalette.setPresented(true)
                },
                onLogGoodDeed: {
                    handle(.logGoodDeed)
                },
                onSetIntention: {
                    handle(.setIntention)
                },
                onReflect: {
                    handle(.reflect)
                }
            )

            // Command Palette (Overlay)
            CommandPaletteView(viewModel: commandPalette)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .onAppear {
            configureCommandHandlers()
        }
    }

    private func configureCommandHandlers() {
        commandPalette.onExecute = { commandID in
            handle(commandID)
        }

        commandPalette.onSubmitPrompt = { prompt in
            withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                let newNode = canvasStore.addIdea(prompt: prompt, viewport: viewport)
                canvasStore.requestFocus(on: newNode.commandID ?? .openToday)
            }
        }
    }

    private func handle(_ commandID: HasanaCommandID) {
        // Focus the node on the canvas when the action is triggered
        canvasStore.requestFocus(on: commandID)
    }
}

#Preview {
    RootView()
}
