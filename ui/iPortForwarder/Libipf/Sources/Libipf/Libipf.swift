import Foundation

import Ipf

public func checkIpIsValid(ip: String) -> Bool {
    let ns_ip = ip as NSString
    let ip_c_string = UnsafeMutablePointer<CChar>(mutating: ns_ip.utf8String)
    return Ipf.ipf_check_ip_is_valid(ip_c_string)
}

public func forward(ip: String, port: UInt16, allowLan: Bool) {
    let ns_ip = ip as NSString
    let ip_c_string = UnsafeMutablePointer<CChar>(mutating: ns_ip.utf8String)
    Ipf.ipf_forward(ip_c_string, port, allowLan)
}
