import SwiftUI

import Libipf

struct ForwardedItemRow: View {
    var item: ForwardedItem?

    var onNewItemAdded: ((_ newItem: ForwardedItem) -> Void)?
    var onChange: ((_ ipAddress: String, _ port: UInt16, _ allowLan: Bool) -> Void)?
    var onCancel: (() -> Void)?

    @State private var ipAddress: String
    @State private var port: UInt16?
    @State private var allowLan: Bool

    init(
        item: ForwardedItem? = nil,
        onNewItemAdded: ((_ newItem: ForwardedItem) -> Void)? = nil,
        onChange: ((_ ipAddress: String, _ port: UInt16, _ allowLan: Bool) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.item = item
        self.onNewItemAdded = onNewItemAdded
        self.onChange = onChange
        self.onCancel = onCancel
        self.ipAddress = item?.source ?? ""
        self.port = item?.port
        self.allowLan = item?.allowLan ?? false
    }

    var body: some View {
        HStack(alignment: .center) {
            HStack {
                TextField("IP Address", text: $ipAddress) {
                }
                .frame(width: 150)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(ipAddress != "" && !checkIpIsValid(ip: ipAddress) ? .red : .primary)

                Text(":")

                TextField("Port", text: Binding(
                    get: {port ==   nil ? "" : String(port!) },
                    set: { port =  UInt16($0) ?? nil }
                ))
                .frame(minWidth: 30, maxWidth: 60)
                .textFieldStyle(.roundedBorder)
            }

            Spacer()

            Toggle("Allow LAN", isOn: $allowLan)
                .toggleStyle(.switch)

            if hasChanged() {
                Spacer()

                Button {
                    if item != nil {
                        if let submitChange = onChange {
                            submitChange(ipAddress, port!, allowLan)
                        }
                    } else if onNewItemAdded != nil {
                        onNewItemAdded!(ForwardedItem(source: ipAddress, port: port!, allowLan: allowLan))
                    }
                } label: {
                    Label("OK", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                        .foregroundColor(isValid() ? .green : .gray)
                }
                .disabled(!isValid())

                Button {
                    reset()
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.blue)
                }

                if item == nil {
                    Button {
                        if let cancel = onCancel {
                            cancel()
                        }
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
    }

    func isValid () -> Bool {
        return ipAddress != "" && port != nil && checkIpIsValid(ip: ipAddress)
    }

    func hasChanged() -> Bool {
        if item == nil {
            return true
        }

        return item!.source != ipAddress || item!.port != port || item!.allowLan != allowLan
    }

    func reset() {
        ipAddress = item?.source ?? ""
        port = item?.port
        allowLan = item?.allowLan ?? false
    }
}

struct ForwardedItemRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForwardedItemRow(item: ForwardedItem(source: "192.168.100.1", port: 1234))
            ForwardedItemRow()
        }
    }
}
