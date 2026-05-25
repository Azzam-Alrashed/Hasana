//
//  ContentView.swift
//  Hasana
//
//  Created by Azzam Alrashed on 25/05/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var commandPalette = CommandPaletteViewModel()
    @State private var recentAction = "Ready for the day"
    @State private var intention = "Work with ihsan, protect salah, and be useful."
    @State private var priorities = [
        "Plan Hasana's Today flow",
        "Review prayer windows around work",
        "Make one quiet act of sadaqah"
    ]

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        intentionCard
                        prioritiesSection
                        prayerSection
                        actionLogSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Hasana")
            }

            FloatingCommandButton(
                onTap: {
                    commandPalette.setPresented(true)
                },
                onLogGoodDeed: {
                    handleCommand(.logGoodDeed)
                },
                onSetIntention: {
                    handleCommand(.setIntention)
                },
                onReflect: {
                    handleCommand(.reflect)
                }
            )

            CommandPaletteView(viewModel: commandPalette)
        }
        .onAppear {
            commandPalette.onExecute = handleCommand
            commandPalette.onSubmitPrompt = { prompt in
                recentAction = "Saved idea: \(prompt)"
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.system(size: 38, weight: .bold))

            Text("Work, worship, and live with intention.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Daily intention", systemImage: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.green)

            Text(intention)
                .font(.system(size: 22, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Priorities")
                .font(.system(size: 20, weight: .bold))

            ForEach(Array(priorities.enumerated()), id: \.offset) { index, priority in
                HStack(spacing: 12) {
                    Image(systemName: "\(index + 1).circle.fill")
                        .foregroundStyle(.teal)

                    Text(priority)
                        .font(.system(size: 16, weight: .medium))

                    Spacer()
                }
                .padding(14)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var prayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prayer")
                .font(.system(size: 20, weight: .bold))

            HStack(spacing: 12) {
                prayerTile(name: "Dhuhr", time: "12:08")
                prayerTile(name: "Asr", time: "15:29")
                prayerTile(name: "Maghrib", time: "18:36")
            }
        }
    }

    private func prayerTile(name: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(time)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var actionLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last action")
                .font(.system(size: 20, weight: .bold))

            Label(recentAction, systemImage: "checkmark.seal")
                .font(.system(size: 16, weight: .medium))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.bottom, 96)
    }

    private func handleCommand(_ command: HasanaCommandID) {
        switch command {
        case .openToday:
            recentAction = "Opened Today"
        case .logGoodDeed:
            recentAction = "Logged a good deed"
        case .setIntention:
            intention = "Renew the intention, then do the next right thing well."
            recentAction = "Updated intention"
        case .addPriority:
            priorities.append("New Hasana priority")
            recentAction = "Added priority"
        case .openPrayerTimes:
            recentAction = "Checked prayer times"
        case .startDhikr:
            recentAction = "Started dhikr"
        case .reflect:
            recentAction = "Opened evening reflection"
        case .addSadaqah:
            recentAction = "Tracked sadaqah"
        }
    }
}

#Preview {
    ContentView()
}
