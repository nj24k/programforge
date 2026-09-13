import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        Group {
            if app.showOnboarding {
                OnboardingView()
            } else {
                TabView {
                    TodayView()
                        .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }
                    ProgressRootView()
                        .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                    ProgramsView()
                        .tabItem { Label("Programs", systemImage: "list.clipboard") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
            }
        }
    }
}
