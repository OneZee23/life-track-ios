import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            CheckInView()
                .tabItem {
                    Label(L10n.tabCheckIn, systemImage: "checkmark.seal.fill")
                }

            ProgressRootView()
                .tabItem {
                    Label(L10n.tabProgress, systemImage: "chart.bar.fill")
                }

            HabitsView()
                .tabItem {
                    Label(L10n.tabHabits, systemImage: "list.bullet.clipboard.fill")
                }
        }
        .tint(Color(UIColor.systemGreen))
    }
}
