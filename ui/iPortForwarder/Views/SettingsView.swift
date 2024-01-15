import AppKit
import SwiftUI
import LaunchAtLogin

extension Array: RawRepresentable where Element: Codable {
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

struct SettingsView: View {
    var window: NSWindow? {
        get {
            return NSApplication.shared.windows.first
        }
    }

    @AppStorage("loadConfigurationsOnStartup") private var loadConfigurationsOnStartup = false
    @AppStorage("configurationsWillBeLoaded") private var configurationsWillBeLoaded: [URL] = []

    var body: some View {
        VStack(alignment: .leading) {
            LaunchAtLogin.Toggle {
                Text("Launch at login")
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
