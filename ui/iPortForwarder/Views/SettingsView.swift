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
    @AppStorage("configurationsWillBeLoaded") private var configurationsWillBeLoaded: [URL] = []

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
                                        if $0 == .OK {
                                            if let openUrl = openPanel.url {
                                                configurationsWillBeLoaded.append(openUrl)
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

                        if configurationsWillBeLoaded.count > 0 {
                            VStack {
                                ForEach(configurationsWillBeLoaded, id: \.absoluteString) {configFile in
                                    HStack {
                                        Text(configFile.lastPathComponent)
                                        Spacer()
                                        Button {
                                            let index = configurationsWillBeLoaded.firstIndex(where: { $0 == configFile })
                                            configurationsWillBeLoaded.remove(at: index!)
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
                            .animation(.spring, value: configurationsWillBeLoaded)
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
