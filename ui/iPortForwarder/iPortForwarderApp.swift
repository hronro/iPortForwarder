import SwiftUI

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

@main
struct iPortForwarderApp: App {
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
        }
    }
}
