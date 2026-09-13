import Foundation

/// Epley one-rep-max estimate.
enum OneRepMax {
    static func epley(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
}

struct PRRecord: Identifiable, Codable, Equatable {
    let lift: Lift
    let estimatedOneRm: Double
    let weight: Double
    let reps: Int
    let date: Date
    var id: String { "\(lift.rawValue)-\(date.timeIntervalSince1970)" }
}

struct LoggedSet: Identifiable, Codable, Equatable {
    let lift: Lift
    let tier: String
    let weight: Double
    let targetReps: Int   // 0 = AMRAP
    let completedReps: Int
    let date: Date
    var id: String { "\(lift.rawValue)-\(date.timeIntervalSince1970)-\(weight)-\(completedReps)" }
}

/// Local persistence via JSON file in Application Support.
final class TrainingStore: ObservableObject {
    static let shared = TrainingStore()

    @Published var trainingMaxes: [Lift: Double] = [:] {
        didSet { persist() }
    }
    @Published var loggedSets: [LoggedSet] = [] {
        didSet { persist() }
    }
    @Published var prs: [PRRecord] = [] {
        didSet { persist() }
    }

    private let fm = FileManager.default
    private var fileURL: URL {
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProgramForge", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("training-store.json")
    }

    private init() { load() }

    private struct Snapshot: Codable {
        var trainingMaxes: [String: Double]
        var loggedSets: [LoggedSet]
        var prs: [PRRecord]
    }

    private func persist() {
        let snap = Snapshot(
            trainingMaxes: trainingMaxes.mapValues { $0 },
            loggedSets: loggedSets,
            prs: prs
        )
        // Map Lift keys to raw strings for Codable
        let wrapped = Snapshot(
            trainingMaxes: snap.trainingMaxes,
            loggedSets: snap.loggedSets,
            prs: snap.prs
        )
        if let data = try? JSONEncoder().encode(wrapped) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        var map: [Lift: Double] = [:]
        for (k, v) in snap.trainingMaxes {
            if let lift = Lift(rawValue: k) { map[lift] = v }
        }
        trainingMaxes = map
        loggedSets = snap.loggedSets
        prs = snap.prs
    }

    func currentE1rm(for lift: Lift) -> Double? {
        let sets = loggedSets.filter { $0.lift == lift }
        guard let best = sets.map({ OneRepMax.epley(weight: $0.weight, reps: $0.completedReps) }).max() else { return nil }
        return best
    }

    func maybeRecordPR(lift: Lift, weight: Double, reps: Int) {
        guard reps >= 1 else { return }
        let e = OneRepMax.epley(weight: weight, reps: reps)
        let existingBest = prs.filter { $0.lift == lift }.map { $0.estimatedOneRm }.max() ?? 0
        if e > existingBest + 0.01 {
            prs.append(PRRecord(lift: lift, estimatedOneRm: e, weight: weight, reps: reps, date: Date()))
        }
    }

    func logSet(_ set: LoggedSet) {
        loggedSets.append(set)
        maybeRecordPR(lift: set.lift, weight: set.weight, reps: set.completedReps)
    }

    func streakDays() -> Int {
        let cal = Calendar.current
        let days = Set(loggedSets.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        if !days.contains(cursor) { cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
        while days.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }
}
