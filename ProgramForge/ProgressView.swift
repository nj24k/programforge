import SwiftUI
import Charts

struct ProgressRootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards
                    e1rmCharts
                }
                .padding()
            }
            .navigationTitle("Progress")
            .background(Theme.bg.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            statCard("Sets", "\(app.store.loggedSets.count)", "figure.strengthtraining.traditional")
            statCard("PRs", "\(app.store.prs.count)", "crown")
            statCard("Streak", "\(app.store.streakDays())", "flame")
        }
    }

    private func statCard(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(Theme.accent)
            Text(value).font(.title2.bold()).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .pfCard()
    }

    private var e1rmCharts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated 1RM")
                .font(.headline)
                .foregroundStyle(.white)
            ForEach(Lift.allCases) { lift in
                LiftChartView(lift: lift, sets: app.store.loggedSets.filter { $0.lift == lift })
                    .frame(height: 120)
            }
        }
        .padding(18)
        .pfCard()
    }
}

struct LiftChartView: View {
    let lift: Lift
    let sets: [LoggedSet]

    private struct Point: Identifiable {
        let date: Date
        let e: Double
        var id: Date { date }
    }

    private var points: [Point] {
        let grouped = Dictionary(grouping: sets) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.map { day, daySets in
            let best = daySets.map { OneRepMax.epley(weight: $0.weight, reps: $0.completedReps) }.max() ?? 0
            return Point(date: day, e: best)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(lift.displayName).font(.caption).foregroundStyle(.secondary)
                Spacer()
                if let last = points.last {
                    Text("\(Int(last.e)) lb e1RM").font(.caption.bold()).foregroundStyle(Theme.accent)
                }
            }
            if points.count >= 2 {
                Chart(points) { p in
                    LineMark(x: .value("Date", p.date), y: .value("e1RM", p.e))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", p.date), y: .value("e1RM", p.e))
                        .foregroundStyle(Theme.accent.opacity(0.12))
                        .interpolationMethod(.catmullRom)
                }
                .chartYAxis { AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 2)) }
            } else {
                Text("Log a few sets to see your curve")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
    }
}
