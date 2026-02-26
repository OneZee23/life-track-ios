import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            CheckInView()
                .tabItem {
                    Label("Чек-ин", systemImage: "checkmark.seal.fill")
                }

            ProgressRootView()
                .tabItem {
                    Label("Прогресс", systemImage: "chart.bar.fill")
                }

            HabitsView()
                .tabItem {
                    Label("Привычки", systemImage: "list.bullet.clipboard.fill")
                }
        }
        .tint(Color(UIColor.systemGreen))
    }
}
