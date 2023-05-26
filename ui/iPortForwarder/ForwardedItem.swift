import Foundation

import Libipf

class ForwardedItem: Identifiable {
    let source: String
    let port: UInt16
    let allowLan: Bool
    private let forwardRuleId: Int8

    init(source: String, port: UInt16, allowLan: Bool = false) {
        self.source = source
        self.port = port
        self.allowLan = allowLan

        self.forwardRuleId = forward(ip: source, port: port, allowLan: allowLan)
    }

    deinit {
        cancelForward(forwardRuleId: self.forwardRuleId)
    }
}
