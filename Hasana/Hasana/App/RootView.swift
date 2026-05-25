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
            // Floating Command (Overlay)
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
        }
    }
}

#Preview {
    RootView()
}
