import Foundation

/// Core domain models for ProgramForge.

enum Lift: String, CaseIterable, Codable, Identifiable {
    case squat, bench, deadlift, ohp
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .squat: return "Squat"
        case .bench: return "Bench Press"
        case .deadlift: return "Deadlift"
        case .ohp: return "Overhead Press"
        }
    }
}

struct Plate: Identifiable, Equatable {
    let weight: Double   // per-plate weight in lb
    let count: Int       // number of pairs
    var id: Double { weight }
}

enum PlateSet {
    /// Standard gym set: 45/35/25/10/5/2.5 lb pairs.
    static let standard: [Double] = [45, 35, 25, 10, 5, 2.5]
    static let barWeight = 45.0

    /// Returns per-side plates for a target total weight. Tries to hit within 0.1 lb.
    static func solve(total target: Double, bar: Double = barWeight) -> [Plate]? {
        var perSide = (target - bar) / 2
        guard perSide >= 0 else { return nil }
        var result: [Plate] = []
        for plate in standard {
            let pairCount = Int((perSide / plate).rounded(.down))
            if pairCount > 0 {
                result.append(Plate(weight: plate, count: pairCount))
                perSide -= Double(pairCount) * plate
            }
            if perSide < 0.05 { break }
        }
        guard perSide < 0.1 else { return nil } // can't make exactly
        return result
    }

    static func achievable(total target: Double, bar: Double = barWeight) -> Bool {
        solve(total: target, bar: bar) != nil
    }
}

/// Rounds a target weight down/up to the nearest achievable weight with standard plates.
enum WeightMath {
    static func roundToPlates(_ target: Double, rounding: FloatingPointRoundingRule, bar: Double = PlateSet.barWeight) -> Double {
        // Try nearest achievable candidates around target.
        let candidates: [Double] = stride(from: max(bar, target - 15), through: target + 15, by: 2.5).map { $0 }
        let achievable = candidates.filter { PlateSet.achievable(total: $0, bar: bar) }
        guard !achievable.isEmpty else { return bar }
        switch rounding {
        case .down:
            return achievable.filter { $0 <= target + 0.01 }.max() ?? bar
        case .toNearestOrAwayFromZero:
            return achievable.min(by: { abs($0 - target) < abs($1 - target) }) ?? bar
        default:
            return achievable.min(by: { abs($0 - target) < abs($1 - target) }) ?? bar
        }
    }
}

struct SetPrescription: Identifiable, Equatable {
    let index: Int          // set number within the exercise
    let reps: Int           // target reps (0 = AMRAP)
    let percentage: Double  // % of training max (0 = fixed weight)
    let fixedWeight: Double // used when percentage == 0
    var id: Int { index }
    var isAmrap: Bool { reps == 0 }
    var label: String {
        if isAmrap { return "AMRAP" }
        return "\(reps)+"
    }
}

struct ExerciseSlot: Identifiable, Equatable {
    let lift: Lift
    let tier: String        // "T1", "T2", "Main", etc.
    let sets: [SetPrescription]
    var id: String { "\(tier)-\(lift.rawValue)" }
}

struct WorkoutDay: Identifiable, Equatable {
    let name: String        // "Day 1 — Squat"
    let exercises: [ExerciseSlot]
    var id: String { name }
}

struct ProgramCycle: Identifiable, Equatable {
    let program: ProgramKind
    let week: Int           // 1-based week within the cycle
    let days: [WorkoutDay]
    var id: String { "\(program.rawValue)-w\(week)" }
}
