import SwiftUI

@main
struct LifeTrackApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.preferredColorScheme)
        }
    }
}
