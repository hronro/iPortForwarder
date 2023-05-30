import Foundation

import Libipf

enum ForwardRule: Equatable {
    case single(port: UInt16)
    case range(start: UInt16, end: UInt16)

    func isSingle() -> Bool {
        switch self {
        case .single(port: _):
            return true
        case .range(start: _, end: _):
            return false
        }
    }

    func isRange() -> Bool {
        switch self {
        case .single(port: _):
            return false
        case .range(start: _, end: _):
            return true
        }
    }

    static func ==(lhs: ForwardRule, rhs: ForwardRule) -> Bool {
        switch lhs {
        case let .single(lPort):
            switch rhs {
            case let .single(rPort):
                return lPort == rPort
            case .range(_, _):
                return false
            }
        case let .range(lStart, lEnd):
            switch rhs {
            case .single(_):
                return false
            case let .range(rStart, rEnd):
                return lStart == rStart && lEnd == rEnd
            }
        }
    }
}

class ForwardedItem: Identifiable {
    let ip: String
    let rule: ForwardRule
    let allowLan: Bool
    private let forwardRuleId: Int8

    init(ip: String, port: UInt16, allowLan: Bool = false) {
        self.ip = ip
        self.rule = .single(port: port)
        self.allowLan = allowLan

        self.forwardRuleId = forward(
            ip: ip,
            remotePort: port,
            localPort: port,
            allowLan: allowLan
        )
    }

    init(ip: String, startPort: UInt16, endPort: UInt16, allowLan: Bool = false) {
        self.ip = ip
        self.rule = .range(start: startPort, end: endPort)
        self.allowLan = allowLan

        self.forwardRuleId = forwardRange(
            ip: ip,
            remotePortStart: startPort,
            remotePortEnd: endPort,
            localPortStart: startPort,
            allowLan: allowLan
        )
    }

    init(ip: String, rule: ForwardRule, allowLan: Bool = false) {
        self.ip = ip
        self.rule = rule
        self.allowLan = allowLan

        switch rule {
        case let .single(port):
            self.forwardRuleId = forward(
                ip: ip,
                remotePort: port,
                localPort: port,
                allowLan: allowLan
            )
        case let .range(startPort, endPort):
            self.forwardRuleId = forwardRange(
                ip: ip,
                remotePortStart: startPort,
                remotePortEnd: endPort,
                localPortStart: startPort,
                allowLan: allowLan
            )
        }
    }

    deinit {
        cancelForward(forwardRuleId: self.forwardRuleId)
    }
}
