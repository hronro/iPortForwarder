import SwiftUI

import Libipf

@main
struct iPortForwarderApp: App {
    @AppStorage("loadConfigurationsOnStartup") private var loadConfigurationsOnStartup = false
    @AppStorage("configurationsWillBeLoadedBookmarks") private var configurationsWillBeLoadedBookmarks: [Data] = []

    init() {
        initLibipfErrorHandler()

        if loadConfigurationsOnStartup {
            for (index, bookmarkData) in configurationsWillBeLoadedBookmarks.enumerated() {
                var stale = false
                do {
                    let configFileURL = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: [.withSecurityScope],
                        relativeTo: nil,
                        bookmarkDataIsStale: &stale
                    )

                    if stale {
                        let newBookmarkData = try configFileURL.bookmarkData(
                            options: [.withSecurityScope],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        configurationsWillBeLoadedBookmarks[index] = newBookmarkData
                    }

                    if configFileURL.startAccessingSecurityScopedResource() {
                        defer { configFileURL.stopAccessingSecurityScopedResource() }

                        let jsonString: String
                        if #available(macOS 13, *) {
                            jsonString = try String(contentsOfFile: configFileURL.path(percentEncoded: false))
                        } else {
                            jsonString = try String(contentsOfFile: configFileURL.path)
                        }

                        let list = try JSONDecoder().decode([ForwardedItemInfo].self, from: jsonString.data(using: .utf8)!)

                        for item in list {
                            globalState.items.append(try ForwardedItem(item: item))
                        }
                    } else {
                        showErrorDialog("Unable to access the configuration file. Please ensure the file exists and that you have granted the necessary permissions.")
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
