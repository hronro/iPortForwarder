import Foundation

import Libipf

class ForwardedItem: Identifiable {
    let source: String
    let port: UInt16
    let allowLan: Bool

    init(source: String, port: UInt16, allowLan: Bool = false) {
        self.source = source
        self.port = port
        self.allowLan = allowLan

        forward(ip: source, port: port, allowLan: allowLan)
    }
}
