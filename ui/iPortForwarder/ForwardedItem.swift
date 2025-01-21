import Foundation

import Libipf

enum Port: Codable, Equatable {
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

protocol DisplayableForwardedItem {
    var address: String { get }
    var remotePort: Port { get }
    var localPort: UInt16? { get }
    var allowLan: Bool { get }
}

class ForwardedItem: DisplayableForwardedItem, Identifiable {
    let address: String
    let remotePort: Port
    let localPort: UInt16?
    let allowLan: Bool
    private let forwardRuleId: Int8
    private var hasDeinit = false

    var id: Int8 {
        get {
            return self.forwardRuleId
        }
    }

    init(
        address: String,
        remotePort: UInt16,
        localPort: UInt16? = nil,
        allowLan: Bool = false
    ) throws {
        self.address = address
        self.remotePort = .single(port: remotePort)
        if let localPort {
            self.localPort = localPort
        } else {
            self.localPort = nil
        }
        self.allowLan = allowLan

        self.forwardRuleId = try forward(
            address: address,
            remotePort: remotePort,
            localPort: remotePort,
            allowLan: allowLan
        )
    }

    init(
        address: String,
        remotePorts: (UInt16, UInt16),
        localStartPort: UInt16?,
        allowLan: Bool = false
    ) throws {
        self.address = address
        self.remotePort = .range(start: remotePorts.0, end: remotePorts.1)
        self.localPort = localStartPort
        self.allowLan = allowLan

        if let localStartPort {
            self.forwardRuleId = try forwardRange(
                address: address,
                remotePortStart: remotePorts.0,
                remotePortEnd: remotePorts.1,
                localPortStart: localStartPort,
                allowLan: allowLan
            )
        } else {
            self.forwardRuleId = try forwardRange(
                address: address,
                remotePortStart: remotePorts.0,
                remotePortEnd: remotePorts.1,
                localPortStart: remotePorts.0,
                allowLan: allowLan
            )
        }
    }

    init(
        address: String,
        remotePort: Port,
        localPort: UInt16? = nil,
        allowLan: Bool = false
    ) throws {
        self.address = address
        self.remotePort = remotePort
        self.localPort = localPort
        self.allowLan = allowLan

        switch remotePort {
        case let .single(port):
            if let localPort {
                self.forwardRuleId = try forward(
                    address: address,
                    remotePort: port,
                    localPort: localPort,
                    allowLan: allowLan
                )
            } else {
                self.forwardRuleId = try forward(
                    address: address,
                    remotePort: port,
                    localPort: port,
                    allowLan: allowLan
                )
            }

        case let .range(startPort, endPort):
            if let localPort {
                self.forwardRuleId = try forwardRange(
                    address: address,
                    remotePortStart: startPort,
                    remotePortEnd: endPort,
                    localPortStart: localPort,
                    allowLan: allowLan
                )
            } else {
                self.forwardRuleId = try forwardRange(
                    address: address,
                    remotePortStart: startPort,
                    remotePortEnd: endPort,
                    localPortStart: startPort,
                    allowLan: allowLan
                )
            }
        }
    }

    init(item: DisplayableForwardedItem) throws {
        self.address = item.address
        self.remotePort = item.remotePort
        self.localPort = item.localPort
        self.allowLan = item.allowLan

        switch remotePort {
        case let .single(port):
            if let localPort {
                self.forwardRuleId = try forward(
                    address: address,
                    remotePort: port,
                    localPort: localPort,
                    allowLan: allowLan
                )
            } else {
                self.forwardRuleId = try forward(
                    address: address,
                    remotePort: port,
                    localPort: port,
                    allowLan: allowLan
                )
            }

        case let .range(startPort, endPort):
            if let localPort {
                self.forwardRuleId = try forwardRange(
                    address: address,
                    remotePortStart: startPort,
                    remotePortEnd: endPort,
                    localPortStart: localPort,
                    allowLan: allowLan
                )
            } else {
                self.forwardRuleId = try forwardRange(
                    address: address,
                    remotePortStart: startPort,
                    remotePortEnd: endPort,
                    localPortStart: startPort,
                    allowLan: allowLan
                )
            }
        }
    }

    deinit {
        if !hasDeinit {
            cancelForward(forwardRuleId: self.forwardRuleId)
        }
    }

    public func destory() {
        cancelForward(forwardRuleId: self.forwardRuleId)
        hasDeinit = true
    }
}

struct ForwardedItemInfo: Codable, DisplayableForwardedItem {
    let address: String

    let remotePort: Port

    let localPort: UInt16?

    let allowLan: Bool

    init(
        address: String,
        remotePort: Port,
        localPort: UInt16? = nil,
        allowLan: Bool = false
    ) {
        self.address = address
        self.remotePort = remotePort
        self.localPort = localPort
        self.allowLan = allowLan
    }

    init(item: DisplayableForwardedItem) {
        self.address = item.address
        self.remotePort = item.remotePort
        self.localPort = item.localPort
        self.allowLan = item.allowLan
    }
}
