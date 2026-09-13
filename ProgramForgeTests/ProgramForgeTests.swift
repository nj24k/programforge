import XCTest
@testable import ProgramForge

final class PlateMathTests: XCTestCase {
    func testSolveExact() {
        // 45 + 2x45 per side = 225
        let plates = PlateSet.solve(total: 225)
        XCTAssertNotNil(plates)
        XCTAssertEqual(plates?.first?.weight, 45)
        XCTAssertEqual(plates?.first?.count, 2)
    }

    func testBarOnly() {
        let plates = PlateSet.solve(total: 45)
        XCTAssertEqual(plates?.count, 0)
    }

    func testTooLight() {
        XCTAssertNil(PlateSet.solve(total: 20))
    }

    func testUnachievableFails() {
        // 47.5 needs a 1.25 plate we don't have
        XCTAssertNil(PlateSet.solve(total: 47.5))
    }

    func testRounding() {
        // 96.7% TM of 300 = 289.5 -> nearest achievable is 285 or 290... 290 not achievable with pairs; 285 is
        let rounded = WeightMath.roundToPlates(289.5, rounding: .down)
        XCTAssertEqual(rounded, 285)
    }
}

final class E1rmTests: XCTestCase {
    func testEpley() {
        XCTAssertEqual(OneRepMax.epley(weight: 225, reps: 1), 225)
        XCTAssertEqual(OneRepMax.epley(weight: 225, reps: 5), 262.5)
    }
}

final class ProgramGeneratorTests: XCTestCase {
    let tm: [Lift: Double] = [.squat: 270, .bench: 180, .deadlift: 315, .ohp: 115]

    func testTrainingMaxIs90Pct() {
        XCTAssertEqual(ProgramGenerator.trainingMax(oneRm: 300), 270)
    }

    func testF531Week1Prescription() {
        let cycle = ProgramGenerator.cycle(program: .fiveThreeOne, week: 1, trainingMaxes: tm)
        XCTAssertEqual(cycle.days.count, 2)
        let main = cycle.days[0].exercises[0]
        XCTAssertEqual(main.sets.map { $0.percentage }, [65, 75, 85])
        XCTAssertEqual(main.sets.map { $0.reps }, [5, 5, 5])
    }

    func testF531Week3HasAMRAP() {
        let cycle = ProgramGenerator.cycle(program: .fiveThreeOne, week: 3, trainingMaxes: tm)
        let main = cycle.days[0].exercises[0]
        XCTAssertTrue(main.sets.contains { $0.isAmrap })
        XCTAssertEqual(main.sets.last?.percentage, 95)
    }

    func testNsunsPrescription() {
        let cycle = ProgramGenerator.cycle(program: .nsuns4, week: 1, trainingMaxes: tm)
        XCTAssertEqual(cycle.days.count, 4)
        let t1 = cycle.days[0].exercises[0]
        XCTAssertTrue(t1.sets.contains { $0.isAmrap })
        XCTAssertEqual(t1.sets.count, 8)
    }

    func testGzclpRotation() {
        let d1 = ProgramGenerator.gzclpDay(day: 1, tm: tm)
        XCTAssertEqual(d1.days[0].exercises[0].lift, .squat)
        let d2 = ProgramGenerator.gzclpDay(day: 2, tm: tm)
        XCTAssertEqual(d2.days[0].exercises[0].lift, .ohp)
    }
}
