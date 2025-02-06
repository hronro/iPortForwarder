import SwiftUI

import Libipf

@main
struct iPortForwarderApp: App {
    @AppStorage("loadConfigurationsOnStartup") private var loadConfigurationsOnStartup = false
    @AppStorage("configurationsWillBeLoaded") private var configurationsWillBeLoaded: [URL] = []

    init() {
        initLibipfErrorHandler()

        if loadConfigurationsOnStartup {
            for configFile in configurationsWillBeLoaded {
                do {
                    var jsonString: String
                    if #available(macOS 13, *) {
                        jsonString = try String(contentsOfFile: configFile.path(percentEncoded: false))
                    } else {
                        jsonString = try String(contentsOfFile: configFile.path)
                    }

                    let list = try JSONDecoder().decode([ForwardedItemInfo].self, from: jsonString.data(using: .utf8)!)

                    for item in list {
                        globalState.items.append(try ForwardedItem(item: item))
                    }
                } catch {
                    showErrorDialog(error)
                }
            }
        }

        Task.detached {
            await AppUpdater.checkForUpdates()
        }
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

        Settings {
            SettingsView()
        }
    }
}
