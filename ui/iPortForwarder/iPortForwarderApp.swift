import SwiftUI
import AppKit

import Libipf

class GlobalState: ObservableObject {
    @Published var items: [ForwardedItem] = []
    @Published var errors: [Int8: [IpfError]] = [:]
    @Published var isAddingNewItem: Bool = false

    public func clear() {
        items = []
        errors = [:]
        isAddingNewItem = false
    }
}

var globalState = GlobalState()

// Disable tab
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

@main
struct iPortForwarderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var window: NSWindow?
    @State private var isMainWindowOpened = false

    init() {
        try! Libipf.registerErrorHandler {
            if var errors = globalState.errors[$0] {
                errors.append($1)
            } else {
                globalState.errors[$0] = [$1]
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor(window: $window))
                .environmentObject(globalState)
                .onAppear {
                    isMainWindowOpened = true
                }
                .onDisappear {
                    isMainWindowOpened = false
                    globalState.clear()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                if isMainWindowOpened {
                    Button("New Forward Item") {
                        withAnimation {
                            globalState.isAddingNewItem = true
                        }
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }

            CommandGroup(replacing: .saveItem) {
                if isMainWindowOpened {
                    Button("Save Current Forwarding List") {
                        let listOfItemInfo = globalState.items.map {
                            ForwardedItemInfo(item: $0)
                        }
                        let jsonData = try! JSONEncoder().encode(listOfItemInfo)
                        let jsonString = String(data: jsonData, encoding: .utf8)!

                        let savePanel = NSSavePanel()
                        savePanel.allowedContentTypes = [.json]
                        savePanel.canCreateDirectories = true
                        savePanel.isExtensionHidden = false
                        savePanel.title = "Save current forwarding list"
                        savePanel.message = "Choose a folder and a name to store the list."
                        savePanel.nameFieldLabel = "List name:"
                        savePanel.beginSheetModal(for: window!) {
                            if $0 == .OK {
                                if let saveUrl = savePanel.url {
                                    do {
                                        try jsonString.write(to: saveUrl, atomically: false, encoding: .utf8)
                                    } catch {
                                        showErrorDialog(error)
                                    }
                                }
                            }
                        }
                    }
                    .keyboardShortcut("s", modifiers: .command)
                }
            }

            CommandGroup(after: .saveItem) {
                if isMainWindowOpened {
                    Button("Import Forwarding List") {
                        let openPanel = NSOpenPanel()
                        openPanel.allowsMultipleSelection = false
                        openPanel.allowedContentTypes = [.json]
                        openPanel.allowsOtherFileTypes = false
                        openPanel.canChooseFiles = true
                        openPanel.canChooseDirectories = false
                        openPanel.canCreateDirectories = false
                        openPanel.isExtensionHidden = false
                        openPanel.title = "Import a forwarding list"
                        openPanel.message = "Choose a forwarding list to import."
                        openPanel.beginSheetModal(for: window!) {
                            if $0 == .OK {
                                if let openUrl = openPanel.url {
                                    do {
                                        var jsonString: String
                                        if #available(macOS 13, *) {
                                            jsonString = try String(contentsOfFile: openUrl.path(percentEncoded: true))
                                        } else {
                                            jsonString = try String(contentsOfFile: openUrl.path)
                                        }

                                        let list = try JSONDecoder().decode([ForwardedItemInfo].self, from: jsonString.data(using: .utf8)!)

                                        try withAnimation {
                                            for item in list {
                                                globalState.items.append(try ForwardedItem(item: item))
                                            }
                                        }
                                    } catch {
                                        showErrorDialog(error)
                                    }
                                }
                            }
                        }
                    }
                    .keyboardShortcut("o", modifiers: .command)
                }
            }
        }
    }
}
