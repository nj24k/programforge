import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(ProgramKind.allCases) { p in
                        Button {
                            app.selectedProgram = p
                            app.cycleWeek = 1
                            app.activeDayIndex = 0
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(p.rawValue).font(.headline).foregroundStyle(.white)
                                    Text(p.blurb).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if app.selectedProgram == p {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.good)
                                }
                            }
                            .padding(18)
                            .pfCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Programs")
            .background(Theme.bg.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Training maxes (lb)") {
                    ForEach(Lift.allCases) { lift in
                        HStack {
                            Text(lift.displayName)
                            Spacer()
                            if let tm = app.store.trainingMaxes[lift] {
                                Text("\(Int(tm))").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Data") {
                    Button("Reset everything", role: .destructive) {
                        app.store.trainingMaxes = [:]
                        app.store.loggedSets = []
                        app.store.prs = []
                        app.selectedProgram = nil
                        app.showOnboarding = true
                    }
                }
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
        }
    }
}
