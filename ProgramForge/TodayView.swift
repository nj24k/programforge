import SwiftUI

struct TodayView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            Group {
                if let day = app.currentDay {
                    ScrollView {
                        VStack(spacing: 16) {
                            weekHeader
                            ForEach(day.exercises) { ex in
                                ExerciseCard(slot: ex, app: app)
                            }
                            completeButton(day: day)
                        }
                        .padding()
                    }
                    .navigationTitle("Today")
                    .background(Theme.bg.ignoresSafeArea())
                } else {
                    Text("Set up your program first.")
                        .foregroundStyle(.secondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var weekHeader: some View {
        let program = app.selectedProgram ?? .fiveThreeOne
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(program.rawValue).font(.caption).foregroundStyle(Theme.accent)
                Text("Week \(app.cycleWeek) · Day \(app.activeDayIndex + 1)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("🔥 \(app.store.streakDays())")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("day streak").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .pfCard()
    }

    private func completeButton(day: WorkoutDay) -> some View {
        Button {
            for ex in day.exercises {
                // Log any sets the user completed; conservative: log targets
                for s in ex.sets where !s.isAmrap {
                    let w = app.weight(for: s, lift: ex.lift)
                    app.store.logSet(LoggedSet(
                        lift: ex.lift, tier: ex.tier, weight: w,
                        targetReps: s.reps, completedReps: s.reps, date: Date()))
                }
            }
            app.completeSession()
        } label: {
            Text("Finish workout")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }
}

struct ExerciseCard: View {
    let slot: ExerciseSlot
    @ObservedObject var app: AppState
    @State private var done: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(slot.tier)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent.opacity(0.2), in: Capsule())
                    .foregroundStyle(Theme.accent)
                Text(slot.lift.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if let tm = app.store.trainingMaxes[slot.lift] {
                    Text("TM \(Int(tm))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(slot.sets) { s in
                let w = app.weight(for: s, lift: slot.lift)
                HStack(spacing: 12) {
                    Text(s.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 64, alignment: .leading)
                    Text("\(Int(w)) lb")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let plates = PlateSet.solve(total: w) {
                        Text(PlateFormatter.platesLabel(plates))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        if done.contains(s.id) { done.remove(s.id) } else { done.insert(s.id) }
                    } label: {
                        Image(systemName: done.contains(s.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(done.contains(s.id) ? Theme.good : .secondary)
                    }
                }
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.cardStroke).frame(height: 1) }
            }
        }
        .padding(18)
        .pfCard()
    }
}

enum PlateFormatter {
    static func platesLabel(_ plates: [Plate]) -> String {
        plates.map { p in
            let n = p.count == 1 ? "1" : "\(p.count)x"
            return "\(n)\(Int(p.weight))"
        }.joined(separator: " ")
    }
}
