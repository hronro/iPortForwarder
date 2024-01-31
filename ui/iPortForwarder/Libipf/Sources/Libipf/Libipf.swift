import Foundation

import Ipf

public enum IpfError: Int8, Error {
    /// Unknown error.
    case unknown = -1

    // Library errors, from -10 to -50.
    /// Invalid C format string.
    case invalidString = -10

    /// The IP address is invalid.
    case invalidIpAddr = -11

    /// At most 128 rules are allowed.
    case tooManyRules = -12

    /// The rule ID is invalid.
    case invalidRuleId = -13

    /// The local port start is invalid,
    /// which will make the local port end greater than 65535.
    case invalidLocalPortStart = -14

    /// The remote port end is invalid.
    case invalidRemotePortEnd = -15

    /// The error handler has already been registered.
    case handlerAlreadyRegistered = -16

    // OS errors, from -51 to -127.
    /// Permission denied.
    case permissionDenied = -51

    /// Address already in use.
    case addrInUse = -52

    /// Address already exists.
    case alreadyExists = -53

    /// An operation could not be completed, because it failed
    /// to allocate enough memory.
    case outOfMemory = -54

    /// Too many open files.
    case tooManyOpenFiles = -55

    public func message() -> String {
        switch self {
        case .unknown:
            return "Unknown error"
        case .invalidString:
            return "Invalid C format string"
        case .invalidIpAddr:
            return "The IP address is invalid"
        case .tooManyRules:
            return "At most 128 rules are allowed"
        case .invalidRuleId:
            return "The forward rule ID is invalid"
        case .invalidLocalPortStart:
            return "The local port start is invalid"
        case .invalidRemotePortEnd:
            return "The remote port end is invalid"
        case .handlerAlreadyRegistered:
            return "The error handler has already been registered"
        case .permissionDenied:
            return "Permission denied"
        case .addrInUse:
            return "Address already in use"
        case .alreadyExists:
            return "Address already exists"
        case .outOfMemory:
            return "Out of memory"
        case .tooManyOpenFiles:
            return "Too many open files"
        }
    }
}

public func checkIpIsValid(ip: String) -> Bool {
    return Ipf.ipf_check_ip_is_valid(ip.cString(using: .utf8))
}

public func forward(
    ip: String,
    remotePort: UInt16,
    localPort: UInt16,
    allowLan: Bool
) throws -> Int8 {
    let returnCode = Ipf.ipf_forward(ip.cString(using: .utf8), remotePort, localPort, allowLan)

    if returnCode < 0 {
        throw IpfError(rawValue: returnCode)!
    }

    return returnCode
}

public func forwardRange(
    ip: String,
    remotePortStart: UInt16,
    remotePortEnd: UInt16,
    localPortStart: UInt16,
    allowLan: Bool
) throws -> Int8 {
    let returnCode = Ipf.ipf_forward_range(
        ip.cString(using: .utf8),
        remotePortStart,
        remotePortEnd,
        localPortStart,
        allowLan
    )

    if returnCode < 0 {
        throw IpfError(rawValue: returnCode)!
    }

    return returnCode
}

public func cancelForward(forwardRuleId: Int8) {
    Ipf.ipf_cancel_forward(forwardRuleId)
}

public func registerErrorHandler(_ handler: @escaping (Int8, IpfError) -> Void) throws {
    if _externalErrorHandler == nil {
        _externalErrorHandler = handler

        let returnCode = Ipf.ipf_register_error_handler(cErrorHandler)

        if returnCode < 0 {
            throw IpfError(rawValue: returnCode)!
        }
    } else {
        throw IpfError.handlerAlreadyRegistered
    }
}

var _externalErrorHandler: ((Int8, IpfError) -> Void)? = nil
func cErrorHandler(ruleId: Int8, errorCode: Int8) {
    let ipfError = IpfError(rawValue: errorCode)!
    if let externalErrorHandler = _externalErrorHandler {
        externalErrorHandler(ruleId, ipfError)
    }
}
