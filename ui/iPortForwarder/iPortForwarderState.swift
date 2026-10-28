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
            // Each port of a range reports its own error, so the same error can be reported many times.
            var errors = globalState.errors[id] ?? []
            if !errors.contains(ipfError) {
                errors.append(ipfError)
                globalState.errors[id] = errors
            }
        }
    }
}
