import Foundation

import Libipf

enum Port: Equatable {
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

    static func ==(lhs: Port, rhs: Port) -> Bool {
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
    let remotePort: Port
    let localPort: UInt16?
    let allowLan: Bool
    private let forwardRuleId: Int8

    var id: Int8 {
        get {
            return self.forwardRuleId
        }
    }

    init(
        ip: String,
        remotePort: UInt16,
        localPort: UInt16? = nil,
        allowLan: Bool = false
    ) {
        self.ip = ip
        self.remotePort = .single(port: remotePort)
        if let localPort {
            self.localPort = localPort
        } else {
            self.localPort = nil
        }
        self.allowLan = allowLan

        self.forwardRuleId = forward(
            ip: ip,
            remotePort: remotePort,
            localPort: remotePort,
            allowLan: allowLan
        )
    }

    init(
        ip: String,
        remotePorts: (UInt16, UInt16),
        localStartPort: UInt16?,
        allowLan: Bool = false
    ) {
        self.ip = ip
        self.remotePort = .range(start: remotePorts.0, end: remotePorts.1)
        self.localPort = localStartPort
        self.allowLan = allowLan

        if let localStartPort {
            self.forwardRuleId = forwardRange(
                ip: ip,
                remotePortStart: remotePorts.0,
                remotePortEnd: remotePorts.1,
                localPortStart: localStartPort,
                allowLan: allowLan
            )
        } else {
            self.forwardRuleId = forwardRange(
                ip: ip,
                remotePortStart: remotePorts.0,
                remotePortEnd: remotePorts.1,
                localPortStart: remotePorts.0,
                allowLan: allowLan
            )
        }
    }

    init(
        ip: String,
        remotePort: Port,
        localPort: UInt16? = nil,
        allowLan: Bool = false
    ) {
        self.ip = ip
        self.remotePort = remotePort
        self.localPort = localPort
        self.allowLan = allowLan

        switch remotePort {
        case let .single(port):
            if let localPort {
                self.forwardRuleId = forward(
                    ip: ip,
                    remotePort: port,
                    localPort: localPort,
                    allowLan: allowLan
                )
            } else {
                self.forwardRuleId = forward(
                    ip: ip,
                    remotePort: port,
                    localPort: port,
                    allowLan: allowLan
                )
            }

        case let .range(startPort, endPort):
            if let localPort {
                self.forwardRuleId = forwardRange(
                    ip: ip,
                    remotePortStart: startPort,
                    remotePortEnd: endPort,
                    localPortStart: localPort,
                    allowLan: allowLan
                )
            } else {
                self.forwardRuleId = forwardRange(
                    ip: ip,
                    remotePortStart: startPort,
                    remotePortEnd: endPort,
                    localPortStart: startPort,
                    allowLan: allowLan
                )
            }
        }
    }

    deinit {
        cancelForward(forwardRuleId: self.forwardRuleId)
    }
}
