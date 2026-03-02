import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.scenePhase) var scenePhase
    @State private var selectedTab = 1
    @State private var progressResetID = UUID()
    @State private var showGreeting = false

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == 1 && selectedTab == 1 {
                    progressResetID = UUID()
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        ZStack {
            TabView(selection: tabSelection) {
                CheckInView()
                    .tabItem {
                        Label(L10n.tabCheckIn, systemImage: "checkmark.seal.fill")
                    }
                    .tag(0)

                ProgressRootView(resetID: progressResetID)
                    .tabItem {
                        Label(L10n.tabProgress, systemImage: "chart.bar.fill")
                    }
                    .tag(1)

                HabitsView()
                    .tabItem {
                        Label(L10n.tabHabits, systemImage: "list.bullet.clipboard.fill")
                    }
                    .tag(2)
            }
            .tint(Color(UIColor.systemGreen))

            if showGreeting {
                DailyGreetingView {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showGreeting = false
                        selectedTab = 0
                    }
                }
            }
        }
        .onAppear { checkGreeting() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { checkGreeting() }
        }
    }

    private func checkGreeting() {
        guard store.shouldShowGreeting() else { return }
        store.markGreetingShown()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            showGreeting = true
        }
    }
}
