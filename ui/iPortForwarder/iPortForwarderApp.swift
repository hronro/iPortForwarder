import SwiftUI

import Libipf

@main
struct iPortForwarderApp: App {
    init() {
        initLibipfErrorHandler()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalState)
                .onDisappear {
                    globalState.clear()
                }
        }
        .commands {
            iPortForwarderCommands()
        }
    }
}
