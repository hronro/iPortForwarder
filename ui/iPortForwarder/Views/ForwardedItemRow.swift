import SwiftUI

import Libipf

struct ForwardedItemRow: View {
    var item: ForwardedItem?

    var onNewItemAdded: ((_ newItem: ForwardedItem) -> Void)?
    var onChange: ((_ ipAddress: String, _ rule: ForwardRule, _ allowLan: Bool) -> Void)?
    var onCancel: (() -> Void)?

    @State private var ipAddress: String
    @State private var rule: ForwardRule
    @State private var allowLan: Bool

    @FocusState private var ipAddrInFocus: Bool
    @FocusState private var startPortInFocus: Bool
    @FocusState private var endPortInFocus: Bool

    init(
        item: ForwardedItem? = nil,
        onNewItemAdded: ((_ newItem: ForwardedItem) -> Void)? = nil,
        onChange: ((_ ipAddress: String, _ rule: ForwardRule, _ allowLan: Bool) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.item = item
        self.onNewItemAdded = onNewItemAdded
        self.onChange = onChange
        self.onCancel = onCancel
        self.ipAddress = item?.ip ?? ""
        self.rule = item?.rule ?? .single(port: 0)
        self.allowLan = item?.allowLan ?? false
    }

    var body: some View {
        HStack {
            HStack {
                TextField("IP Address", text: $ipAddress.animation()) {
                }
                .frame(width: 150)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(ipAddress != "" && !checkIpIsValid(ip: ipAddress) ? .red : .primary)
                .focused($ipAddrInFocus)
                .onAppear {
                    // auto focus when this show from `AddNew` button click
                    if item == nil {
                        self.ipAddrInFocus = true
                    }
                }

                Text(":")

                TextField(rule.isSingle() ? "Port" : "Start", text: Binding(
                    get: {
                        switch rule {
                        case let .single(port):
                            return port == 0 ? "" : String(port)
                        case let .range(startPort, _):
                            return startPort == 0 ? "" : String(startPort)
                        }
                    },
                    set: {
                        switch rule {
                        case .single(_):
                            rule = .single(port: UInt16($0) ?? 0)
                        case let .range(start: _, end: endPort):
                            rule = .range(start: UInt16($0) ?? 0, end: endPort)
                        }
                    }
                ).animation())
                .frame(minWidth: 30, maxWidth: 60)
                .textFieldStyle(.roundedBorder)
                .focused($startPortInFocus)

                if case let .range(startPort, endPort) = rule {
                    HStack {
                        Text ("~")

                        TextField("End", text: Binding(
                            get: { endPort == 0 ? "" : String(endPort) },
                            set: {
                                rule = .range(start: startPort, end: UInt16($0) ?? 0)
                            }
                        ))
                        .frame(minWidth: 30, maxWidth: 60)
                        .textFieldStyle(.roundedBorder)
                        .focused($endPortInFocus)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Button {
                    switch rule {
                    case let .single(port):
                        if port == 0 {
                            startPortInFocus = true
                        } else {
                            endPortInFocus = true
                        }
                        withAnimation {
                            rule = .range(start: port, end: 0)
                        }
                    case let .range(startPort, _):
                        startPortInFocus = true
                        // a hack to make it work
                        if endPortInFocus {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation {
                                    rule = .single(port: startPort)
                                }
                            }
                        } else {
                            withAnimation {
                                rule = .single(port: startPort)
                            }
                        }

                    }
                } label: {
                    if rule.isSingle() {
                        Label("Switch to a range of ports", systemImage: "shuffle.circle")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.gray)
                    } else {
                        Label("Switch to a single port", systemImage: "shuffle.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.purple)
                    }
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            Toggle("Allow LAN", isOn: $allowLan.animation())
                .toggleStyle(.switch)
                .transition(.slide)

            if hasChanged() {
                Spacer()

                HStack {
                    Button {
                        if item != nil {
                            withAnimation {
                                if let onChange {
                                    onChange(ipAddress, rule, allowLan)
                                }
                            }
                        } else if onNewItemAdded != nil {
                            onNewItemAdded!(ForwardedItem(ip: ipAddress, rule: rule, allowLan: allowLan))
                        }
                    } label: {
                        Label("OK", systemImage: "checkmark")
                            .labelStyle(.iconOnly)
                            .foregroundColor(isValid() ? .green : .gray)
                    }
                    .disabled(!isValid())

                    Button {
                        withAnimation {
                            reset()
                        }
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
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    func isValid () -> Bool {
        if ipAddress == "" {
            return false
        }

        switch rule {
        case let .single(port):
            if port == 0 {
                return false
            }

        case let .range(startPort, endPort):
            if startPort == 0 || endPort == 0 {
                return false
            }
        }

        return checkIpIsValid(ip: ipAddress)
    }

    func hasChanged() -> Bool {
        if item == nil {
            return true
        }

        return item!.ip != ipAddress || item!.rule != rule || item!.allowLan != allowLan
    }

    func reset() {
        ipAddress = item?.ip ?? ""
        rule = item?.rule ?? .single(port: 0)
        allowLan = item?.allowLan ?? false
    }
}

struct ForwardedItemRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForwardedItemRow(item: ForwardedItem(ip: "192.168.100.1", rule: .single(port: 1234)))
            ForwardedItemRow(item: ForwardedItem(ip: "192.168.100.1", rule: .range(start: 1000, end: 2000)))
            ForwardedItemRow()
        }
    }
}
