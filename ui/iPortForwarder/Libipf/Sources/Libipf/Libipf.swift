import Foundation

import Ipf

public func checkIpIsValid(ip: String) -> Bool {
    let ns_ip = ip as NSString
    let ip_c_string = UnsafeMutablePointer<CChar>(mutating: ns_ip.utf8String)
    return Ipf.ipf_check_ip_is_valid(ip_c_string)
}

public func forward(
    ip: String,
    remotePort: UInt16,
    localPort: UInt16,
    allowLan: Bool
) -> Int8 {
    let ns_ip = ip as NSString
    let ip_c_string = UnsafeMutablePointer<CChar>(mutating: ns_ip.utf8String)
    return Ipf.ipf_forward(ip_c_string, remotePort, localPort, allowLan)
}

public func forwardRange(
    ip: String,
    remotePortStart: UInt16,
    remotePortEnd: UInt16,
    localPortStart: UInt16,
    allowLan: Bool
) -> Int8 {
    let ns_ip = ip as NSString
    let ip_c_string = UnsafeMutablePointer<CChar>(mutating: ns_ip.utf8String)
    return Ipf.ipf_forward_range(
        ip_c_string,
        remotePortStart,
        remotePortEnd,
        localPortStart,
        allowLan
    )
}

public func cancelForward(forwardRuleId: Int8) {
    Ipf.ipf_cancel_forward(forwardRuleId)
}
