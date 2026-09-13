import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedProgram: ProgramKind? {
        didSet { UserDefaults.standard.set(selectedProgram?.rawValue, forKey: "pf.program") }
    }
    @Published var cycleWeek: Int {
        didSet { UserDefaults.standard.set(cycleWeek, forKey: "pf.week") }
    }
    @Published var activeDayIndex: Int = 0
    @Published var showOnboarding: Bool

    let store = TrainingStore.shared

    init() {
        let programRaw = UserDefaults.standard.string(forKey: "pf.program")
        selectedProgram = programRaw.flatMap(ProgramKind.init(rawValue:))
        cycleWeek = UserDefaults.standard.integer(forKey: "pf.week")
        if cycleWeek < 1 { cycleWeek = 1 }
        showOnboarding = (selectedProgram == nil || store.trainingMaxes.isEmpty)
    }

    var currentCycle: ProgramCycle? {
        guard let program = selectedProgram else { return nil }
        return ProgramGenerator.cycle(program: program, week: cycleWeek, trainingMaxes: store.trainingMaxes)
    }

    var currentDay: WorkoutDay? {
        guard let cycle = currentCycle else { return nil }
        let idx = min(activeDayIndex, cycle.days.count - 1)
        return cycle.days[idx]
    }

    func weight(for set: SetPrescription, lift: Lift) -> Double {
        guard let tm = store.trainingMaxes[lift] else { return PlateSet.barWeight }
        let target = tm * set.percentage / 100.0
        return WeightMath.roundToPlates(target, rounding: .down)
    }

    func startSession(dayIndex: Int) {
        activeDayIndex = dayIndex
    }

    func completeSession() {
        let program = selectedProgram ?? .fiveThreeOne
        cycleWeek += 1
        activeDayIndex = 0
        _ = program
    }
}
