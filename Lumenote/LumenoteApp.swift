//

import SwiftUI

@main
struct LumenoteApp: App {
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
