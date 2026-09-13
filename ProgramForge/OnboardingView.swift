import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppState
    @State private var step = 0
    @State private var program: ProgramKind = .fiveThreeOne
    @State private var oneRmText: [Lift: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            if step == 0 { welcome } else { maxesForm }
        }
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text("ProgramForge")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("You follow the program.\nWe do the math.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            ForEach(ProgramKind.allCases) { p in
                Button {
                    program = p
                    withAnimation { step = 1 }
                } label: {
                    HStack {
                        Text(p.rawValue).font(.headline)
                        Spacer()
                        Text(p.blurb).font(.caption).foregroundStyle(.secondary).lineLimit(2).frame(maxWidth: 180, alignment: .trailing)
                        Image(systemName: "chevron.right").foregroundStyle(Theme.accent)
                    }
                    .padding(18)
                    .pfCard()
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 12)
        }
        .padding(24)
    }

    private var maxesForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Your \(program.rawValue) training maxes")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Enter your current one-rep max in lb. We use 90% as your training max.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Lift.allCases) { lift in
                    HStack {
                        Text(lift.displayName)
                            .foregroundStyle(.white)
                        Spacer()
                        TextField("0", text: Binding(
                            get: { oneRmText[lift] ?? "" },
                            set: { oneRmText[lift] = $0.filter { "0123456789".contains($0) } }
                        ))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .padding(10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                    }
                    .padding(16)
                    .pfCard()
                }
                Button {
                    save()
                } label: {
                    Text("Start training")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func save() {
        var maxes: [Lift: Double] = [:]
        for (lift, text) in oneRmText {
            if let v = Double(text), v >= 45 {
                maxes[lift] = ProgramGenerator.trainingMax(oneRm: v)
            }
        }
        guard maxes.count == Lift.allCases.count else { return }
        app.store.trainingMaxes = maxes
        app.selectedProgram = program
        app.cycleWeek = 1
        app.showOnboarding = false
    }
}
