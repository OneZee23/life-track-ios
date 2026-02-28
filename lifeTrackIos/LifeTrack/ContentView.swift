import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab = 1
    @State private var progressResetID = UUID()

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
    }
}
