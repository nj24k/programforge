import Foundation

enum ProgramKind: String, CaseIterable, Codable, Identifiable {
    case fiveThreeOne = "5/3/1"
    case gzclp = "GZCLP"
    case nsuns4 = "nSuns 4-Day"
    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .fiveThreeOne: return "Jim Wendler's classic. Slow-burn strength, 4 weeks per cycle."
        case .gzclp: return "Linear progression with T1/T2 tiers. Great for newer lifters."
        case .nsuns4: return "High-volume 5/3/1 variant. Lots of PR-set opportunities."
        }
    }

    var weeksPerCycle: Int {
        switch self {
        case .fiveThreeOne: return 4
        case .gzclp, .nsuns4: return 1
        }
    }
}

/// Generates the full prescription for a given program / week / day,
/// based on the lifter's training maxes.
enum ProgramGenerator {

    static func trainingMax(oneRm: Double) -> Double {
        (oneRm * 0.9).rounded()
    }

    static func cycle(program: ProgramKind, week: Int, trainingMaxes: [Lift: Double]) -> ProgramCycle {
        switch program {
        case .fiveThreeOne: return f531Cycle(week: week, tm: trainingMaxes)
        case .gzclp: return gzclpDay(day: week, tm: trainingMaxes)
        case .nsuns4: return nsunsCycle(week: week, tm: trainingMaxes)
        }
    }

    // MARK: - 5/3/1 (4-week cycle, main lift + BBB accessory)

    private static func f531Set(week: Int) -> [SetPrescription] {
        switch week {
        case 1: return [sp(1, reps: 5, pct: 65), sp(2, reps: 5, pct: 75), sp(3, reps: 5, pct: 85)]
        case 2: return [sp(1, reps: 3, pct: 70), sp(2, reps: 3, pct: 80), sp(3, reps: 3, pct: 90)]
        case 3: return [sp(1, reps: 5, pct: 75), sp(2, reps: 3, pct: 85), sp(3, reps: 0, pct: 95)]
        default: return [sp(1, reps: 5, pct: 40), sp(2, reps: 5, pct: 50), sp(3, reps: 5, pct: 60)]
        }
    }

    private static func f531Day(name: String, mainA: Lift, mainB: Lift, week: Int) -> WorkoutDay {
        func mainSets(_ lift: Lift) -> ExerciseSlot {
            ExerciseSlot(lift: lift, tier: "5/3/1", sets: f531Set(week: week))
        }
        let bbbSets = (1...5).map { i in SetPrescription(index: i, reps: 10, percentage: 50, fixedWeight: 0) }
        return WorkoutDay(
            name: name,
            exercises: [
                mainSets(mainA),
                ExerciseSlot(lift: mainB, tier: "BBB", sets: bbbSets)
            ]
        )
    }

    private static func f531Cycle(week: Int, tm: [Lift: Double]) -> ProgramCycle {
        let days: [WorkoutDay]
        switch ((week - 1) % 4) + 1 {
        case 1: days = [
            f531Day(name: "Day 1 — Squat", mainA: .squat, mainB: .bench, week: week),
            f531Day(name: "Day 2 — Overhead Press", mainA: .ohp, mainB: .deadlift, week: week)
        ]
        case 2: days = [
            f531Day(name: "Day 3 — Bench Press", mainA: .bench, mainB: .squat, week: week),
            f531Day(name: "Day 4 — Deadlift", mainA: .deadlift, mainB: .ohp, week: week)
        ]
        case 3: days = [
            f531Day(name: "Day 1 — Squat", mainA: .squat, mainB: .bench, week: week),
            f531Day(name: "Day 2 — Overhead Press", mainA: .ohp, mainB: .deadlift, week: week)
        ]
        default: days = [
            f531Day(name: "Day 3 — Bench Press", mainA: .bench, mainB: .squat, week: week),
            f531Day(name: "Day 4 — Deadlift", mainA: .deadlift, mainB: .ohp, week: week)
        ]
        }
        return ProgramCycle(program: .fiveThreeOne, week: week, days: days)
    }

    // MARK: - GZCLP (4-day, T1/T2 per day, linear)

    private static func gzclpSchemes(phase: Int) -> (t1: [(reps: Int, pct: Double)], t2: [(reps: Int, pct: Double)]) {
        switch phase {
        case 1: return ([(5, 0.85), (3, 0.90), (1, 0.95)], [(10, 0.65), (10, 0.65), (10, 0.65)])
        case 2: return ([(3, 0.85), (3, 0.90), (3, 0.95)], [(10, 0.65), (10, 0.65), (10, 0.65)])
        default: return ([(5, 0.85), (5, 0.90), (5, 0.95)], [(10, 0.65), (10, 0.65), (10, 0.65)])
        }
    }

    static func gzclpDay(day: Int, tm: [Lift: Double]) -> ProgramCycle {
        let phase = ((day - 1) % 3) + 1
        let scheme = gzclpSchemes(phase: phase)
        let rotation: [(Lift, Lift)] = [(.squat, .bench), (.ohp, .deadlift), (.bench, .squat), (.deadlift, .ohp)]
        let idx = (day - 1) % 4
        let (t1, t2) = rotation[idx]
        let t1Sets = scheme.t1.enumerated().map { i, s in
            SetPrescription(index: i + 1, reps: s.reps, percentage: s.pct * 100, fixedWeight: 0)
        }
        let t2Sets = scheme.t2.enumerated().map { i, s in
            SetPrescription(index: i + 1, reps: s.reps, percentage: s.pct * 100, fixedWeight: 0)
        }
        let d = WorkoutDay(
            name: "Day \(idx + 1) — \(t1.displayName)",
            exercises: [
                ExerciseSlot(lift: t1, tier: "T1", sets: t1Sets),
                ExerciseSlot(lift: t2, tier: "T2", sets: t2Sets)
            ]
        )
        return ProgramCycle(program: .gzclp, week: day, days: [d])
    }

    // MARK: - nSuns 4-Day

    private static func nsunsDay(name: String, t1: Lift, t2: Lift) -> WorkoutDay {
        let t1Pcts: [Double]
        if name.contains("Squat") {
            t1Pcts = [75, 85, 95, 90, 85, 80, 75, 70]
        } else if name.contains("Bench") {
            t1Pcts = [75, 90, 95, 85, 80, 75, 70, 65]
        } else if name.contains("Deadlift") {
            t1Pcts = [70, 80, 85, 85, 75, 70, 65]
        } else {
            t1Pcts = [65, 75, 85, 85, 75, 70, 65]
        }
        var t1Sets: [SetPrescription] = []
        for (i, p) in t1Pcts.enumerated() {
            let isAmrap = i == 2
            t1Sets.append(SetPrescription(index: i + 1, reps: isAmrap ? 0 : 3, percentage: p, fixedWeight: 0))
        }
        let t2Sets = (1...5).map { i in SetPrescription(index: i, reps: 8, percentage: 55, fixedWeight: 0) }
        return WorkoutDay(
            name: name,
            exercises: [
                ExerciseSlot(lift: t1, tier: "T1", sets: t1Sets),
                ExerciseSlot(lift: t2, tier: "T2", sets: t2Sets)
            ]
        )
    }

    private static func nsunsCycle(week: Int, tm: [Lift: Double]) -> ProgramCycle {
        let days = [
            nsunsDay(name: "Day 1 — Squat", t1: .squat, t2: .ohp),
            nsunsDay(name: "Day 2 — Bench", t1: .bench, t2: .deadlift),
            nsunsDay(name: "Day 3 — Deadlift", t1: .deadlift, t2: .bench),
            nsunsDay(name: "Day 4 — Overhead Press", t1: .ohp, t2: .squat)
        ]
        return ProgramCycle(program: .nsuns4, week: week, days: days)
    }

    private static func sp(_ i: Int, reps: Int, pct: Double) -> SetPrescription {
        SetPrescription(index: i, reps: reps, percentage: pct, fixedWeight: 0)
    }
}

