import AppKit

import Libipf

@MainActor func showErrorDialog(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = "Error"
    switch error {
    case let ipfError as IpfError:
        alert.informativeText = "\(ipfError.message())."
    default:
        alert.informativeText = error.localizedDescription
    }
    alert.alertStyle = NSAlert.Style.critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

@MainActor func showErrorDialog(_ errorText: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = errorText
    alert.alertStyle = NSAlert.Style.critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
}
