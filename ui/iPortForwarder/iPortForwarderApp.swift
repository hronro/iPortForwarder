import SwiftUI

import Libipf

var errorsOfForwardRules: [Int8: [IpfError]] = [:]

@main
struct iPortForwarderApp: App {
    init() {
        try! Libipf.registerErrorHandler {
            if var errors = errorsOfForwardRules[$0] {
                errors.append($1)
            } else {
                errorsOfForwardRules[$0] = [$1]
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
