import Foundation

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

@MainActor var globalState = GlobalState()

func initLibipfErrorHandler() {
    try! Libipf.registerErrorHandler { id, ipfError in
        DispatchQueue.main.async {
            if var errors = globalState.errors[id] {
                errors.append(ipfError)
            } else {
                globalState.errors[id] = [ipfError]
            }
        }
    }
}
