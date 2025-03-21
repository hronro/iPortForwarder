import AppKit
import ServiceManagement
import SwiftUI

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

class LaunchingAtLogin: ObservableObject {
    var enabled: Bool {
        get {
            if #available(macOS 13, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return false
            }
        }

        set {
            if #available(macOS 13, *) {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }

                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
                objectWillChange.send()
            }
        }
    }
}

struct SettingsView: View {
    var window: NSWindow? {
        get {
            return NSApplication.shared.windows.first
        }
    }

    @StateObject private var launchingAtLogin = LaunchingAtLogin()

    @AppStorage("loadConfigurationsOnStartup") private var loadConfigurationsOnStartup = false
    @AppStorage("configurationsWillBeLoadedBookmarks") private var configurationsWillBeLoadedBookmarks: [Data] = []

    var body: some View {
        VStack(alignment: .leading) {
            if #available(macOS 13, *) {
                Toggle("Launch at login", isOn: $launchingAtLogin.enabled)
            }

            Toggle("Load configurations at startup", isOn: $loadConfigurationsOnStartup)

            VStack {
                if loadConfigurationsOnStartup {
                    VStack {
                        HStack(alignment: .center) {
                            Spacer()
                            Button {
                                if let window {
                                    let openPanel = NSOpenPanel()
                                    openPanel.allowsMultipleSelection = false
                                    openPanel.allowedContentTypes = [.json]
                                    openPanel.allowsOtherFileTypes = false
                                    openPanel.canChooseFiles = true
                                    openPanel.canChooseDirectories = false
                                    openPanel.canCreateDirectories = false
                                    openPanel.isExtensionHidden = false
                                    openPanel.title = "Choose a configuration"
                                    openPanel.message = "Add a new configuration that loads at startup."
                                    openPanel.beginSheetModal(for: window) {
                                        if $0 == .OK, let openUrl = openPanel.url {
                                            do {
                                                let bookmarkData = try openUrl.bookmarkData(
                                                    options: [.withSecurityScope],
                                                    includingResourceValuesForKeys: nil,
                                                    relativeTo: nil
                                                )
                                                configurationsWillBeLoadedBookmarks.append(bookmarkData)
                                            } catch {
                                                showErrorDialog(error)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label("Add New Configuration", systemImage: "plus")
                                    .labelStyle(.iconOnly)
                            }
                            Spacer()
                        }

                        if configurationsWillBeLoadedBookmarks.count > 0 {
                            VStack {
                                ForEach(configurationsWillBeLoadedBookmarks, id: \.self) { bookmarkData in
                                    let displayName: String = {
                                        var stale = false
                                        if let url = try? URL(
                                            resolvingBookmarkData: bookmarkData,
                                            options: [.withSecurityScope],
                                            relativeTo: nil,
                                            bookmarkDataIsStale: &stale
                                        ) {
                                            return url.lastPathComponent
                                        }
                                        return "Unknown"
                                    }()

                                    HStack {
                                        Text(displayName)
                                        Spacer()
                                        Button {
                                            if let index = configurationsWillBeLoadedBookmarks.firstIndex(of: bookmarkData) {
                                                configurationsWillBeLoadedBookmarks.remove(at: index)
                                            }
                                        } label: {
                                            Label("Delete Configuration", systemImage: "trash.fill")
                                                .labelStyle(.iconOnly)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .padding()
                            .background {
                                Color(NSColor.controlBackgroundColor)
                            }
                            .cornerRadius(8)
                            .animation(.spring, value: configurationsWillBeLoadedBookmarks)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring, value: loadConfigurationsOnStartup)
        }.padding()
    }
}

#Preview {
    SettingsView()
}
