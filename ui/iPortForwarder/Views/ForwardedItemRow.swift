import AppKit
import SwiftUI

import Libipf

extension IpfError: @retroactive Identifiable {
    public var id: Int8 {
        return self.rawValue
    }
}

struct ForwardedItemRow: View {
    var item: DisplayableForwardedItem?
    var errors: [IpfError]?

    var onNewItemAdded: ((_ newItem: ForwardedItem) -> Void)?
    var onChange: ((_ ipAddress: String, _ remotePort: Port, _ localPort: UInt16?, _ allowLan: Bool) -> Void)?
    var onCancel: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var address: String
    @State private var remotePort: Port
    @State private var localPort: UInt16?
    @State private var allowLan: Bool

    @State private var showSettings: Bool = false
    @State private var errorsHovered: Bool = false

    @FocusState private var addrInFocus: Bool
    @FocusState private var remoteStartPortInFocus: Bool
    @FocusState private var remoteEndPortInFocus: Bool
    @FocusState private var localPortInFocus: Bool

    var localPortEnd: UInt16 {
        get {
            if let localPort {
                switch remotePort {
                case .single(_):
                    return 0
                case .range(let start, let end):
                    if start == 0 {
                        return 0
                    } else if end == 0 {
                        return 0
                    } else if localPort == 0 {
                        return 0
                    } else if end < start {
                        return 0
                    } else if UInt16.max - (end - start) < localPort {
                        return 0
                    } else {
                        return end - start + localPort
                    }
                }
            } else {
                return 0
            }
        }
    }

    init(
        item: DisplayableForwardedItem? = nil,
        errors: [IpfError]? = nil,
        onNewItemAdded: ((_ newItem: ForwardedItem) -> Void)? = nil,
        onChange: ((_ ipAddress: String, _ remotePort: Port, _ localPort: UInt16?, _ allowLan: Bool) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.item = item
        self.errors = errors
        self.onNewItemAdded = onNewItemAdded
        self.onChange = onChange
        self.onCancel = onCancel
        self.onDelete = onDelete
        self._address = State(initialValue: item?.address ?? "")
        self._remotePort = State(initialValue: item?.remotePort ?? .single(port: 0))
        self._localPort = State(initialValue: item?.localPort)
        self._allowLan = State(initialValue: item?.allowLan ?? false)
    }

    var body: some View {
        VStack {
            HStack {
                HStack {
                    ZStack {
                        if let errors {
                            if !errors.isEmpty {
                                Spacer()
                                    .frame(width: 36)

                                Image(systemName: "x.circle.fill")
                                    .foregroundColor(.red)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }
                    .onHover {
                        let hovered = $0
                        withAnimation {
                            errorsHovered = hovered
                        }
                    }
                    .animation(.spring(), value: errors)

                    TextField("IP Address or Domain Name", text: $address.animation()) {}
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            HStack {
                                Spacer()
                                if address != "" && checkIpIsValid(ip: address) {
                                    Text("IP")
                                        .frame(width: 16, height: 16)
                                        .font(.system(size: 8))
                                        .foregroundStyle(.gray)
                                        .border(.gray, width: 2)
                                        .cornerRadius(4)
                                        .padding(.trailing, 5)
                                }
                            }
                        )
                        .focused($addrInFocus)
                        .onAppear {
                            // auto focus when this show from `AddNew` button click
                            if item == nil {
                                self.addrInFocus = true
                            }
                        }

                    Text(":")

                    TextField(remotePort.isSingle() ? "Port" : "Start", text: Binding(
                        get: {
                            switch remotePort {
                            case let .single(port):
                                return port == 0 ? "" : String(port)
                            case let .range(startPort, _):
                                return startPort == 0 ? "" : String(startPort)
                            }
                        },
                        set: {
                            switch remotePort {
                            case .single(_):
                                remotePort = .single(port: UInt16($0) ?? 0)
                            case let .range(start: _, end: endPort):
                                remotePort = .range(start: UInt16($0) ?? 0, end: endPort)
                            }
                        }
                    ).animation())
                    .frame(minWidth: 30, maxWidth: 60)
                    .textFieldStyle(.roundedBorder)
                    .focused($remoteStartPortInFocus)

                    if case let .range(startPort, endPort) = remotePort {
                        HStack {
                            Text ("~")

                            TextField("End", text: Binding(
                                get: { endPort == 0 ? "" : String(endPort) },
                                set: {
                                    remotePort = .range(start: startPort, end: UInt16($0) ?? 0)
                                }
                            ))
                            .frame(minWidth: 30, maxWidth: 60)
                            .textFieldStyle(.roundedBorder)
                            .focused($remoteEndPortInFocus)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    Button {
                        switch remotePort {
                        case let .single(port):
                            if port == 0 {
                                remoteStartPortInFocus = true
                            } else {
                                remoteEndPortInFocus = true
                            }
                            withAnimation {
                                remotePort = .range(start: port, end: 0)
                            }
                        case let .range(startPort, _):
                            // a hack to make it work
                            if remoteEndPortInFocus {
                                remoteEndPortInFocus = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation {
                                        remotePort = .single(port: startPort)
                                    }
                                }
                            } else {
                                withAnimation {
                                    remotePort = .single(port: startPort)
                                }
                            }
                        }
                    } label: {
                        if remotePort.isSingle() {
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
                    .help(remotePort.isSingle() ? "Switch to forward a range of ports" : "Switch to forward a single por")
                }

                Spacer()

                HStack {
                    if item != nil {
                        Button {
                            withAnimation(.spring()) {
                                showSettings.toggle()
                            }
                        } label: {
                            Label(showSettings ? "Hide advanced settings" : "Show advanced settings", systemImage: "gear")
                                .labelStyle(.iconOnly)
                                .foregroundColor(showSettings ? .accentColor : .primary)
                        }
                        .help(showSettings ? "Hide advanced settings" : "Show advanced settings")
                    }

                    if hasChanged() {
                        HStack {
                            Button {
                                submit()
                            } label: {
                                Label("OK", systemImage: "checkmark")
                                    .labelStyle(.iconOnly)
                                    .foregroundColor(isValid() ? .green : .gray)
                            }
                            .help("OK")
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
                            .help("Reset")

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
                                .help("Cancel")
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .frame(height: 32)

            if showSettings || item == nil {
                HStack {
                    Toggle(
                        remotePort.isSingle() ? "Use a different local port" : "Use different local ports",
                        isOn: Binding(
                            get: { localPort != nil },
                            set: {
                                if $0 {
                                    withAnimation {
                                        localPort = 0
                                        localPortInFocus = true
                                    }
                                } else {
                                    // a hack to make it work
                                    if localPortInFocus {
                                        localPortInFocus = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            withAnimation {
                                                localPort = nil
                                            }
                                        }
                                    } else {
                                        withAnimation {
                                            localPort = nil
                                        }
                                    }
                                }
                            }
                        )
                    )
                    .toggleStyle(.switch)

                    if let localPort {
                        HStack {
                            switch remotePort {
                            case .single(_):
                                TextField("Port", text: Binding(
                                    get: { localPort == 0 ? "" : String(localPort) },
                                    set: {
                                        self.localPort = UInt16($0) ?? 0
                                    }
                                ))
                                .frame(minWidth: 30, maxWidth: 60)
                                .textFieldStyle(.roundedBorder)
                                .focused($localPortInFocus)
                            case .range(_, _):
                                TextField("Start Port", text: Binding(
                                    get: { localPort == 0 ? "" : String(localPort) },
                                    set: {
                                        self.localPort = UInt16($0) ?? 0
                                    }
                                ))
                                .frame(minWidth: 30, maxWidth: 60)
                                .textFieldStyle(.roundedBorder)
                                .focused($localPortInFocus)

                                Text("~")

                                Text(String(localPortEnd))
                            }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    Spacer()
                        .frame(width: 32)

                    Toggle("Allow LAN", isOn: $allowLan.animation())
                        .toggleStyle(.switch)
                        .help("Switch between binding to either 127.0.0.1 or 0.0.0.0")
                        .transition(.slide)

                    Spacer()

                    if item != nil {
                        Button {
                            if let delete = onDelete {
                                delete()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.red)
                        }
                        .help("Delete")
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack {
                if let errors {
                    if errorsHovered {
                        HStack {
                            VStack {
                                Spacer()
                                    .frame(height: 8)
                                ForEach(errors) {
                                    let errorMsg = $0.message()
                                    HStack {
                                        Text(errorMsg)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 1)
                                }
                                Spacer()
                                    .frame(height: 8)
                            }
                            .background(.red)
                            .cornerRadius(8)

                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(), value: errorsHovered)
        }
        .onSubmit {
            if isValid() {
                submit()
            }
        }
        .onExitCommand {
            if let cancel = onCancel {
                cancel()
            }
        }
    }

    func isValid () -> Bool {
        if address == "" {
            return false
        }

        switch remotePort {
        case let .single(port):
            if port == 0 {
                return false
            }

            if let localPort = localPort {
                if localPort == 0 {
                    return false
                }
            }

        case let .range(startPort, endPort):
            if startPort == 0 || endPort == 0 {
                return false
            }
            if endPort <= startPort {
                return false
            }
            if let localPort {
                if UInt16.max - (endPort - startPort) < localPort {
                    return false
                }
            }
        }

        return true
    }

    func hasChanged() -> Bool {
        if item == nil {
            return true
        }

        return item!.address != address || item!.remotePort != remotePort || item!.localPort != localPort || item!.allowLan != allowLan
    }

    func submit() {
        if item != nil {
            withAnimation {
                if let onChange {
                    onChange(address, remotePort, localPort, allowLan)
                }
            }
        } else if let onNewItemAdded {
            do {
                let newItem =
                try ForwardedItem(address: address, remotePort: remotePort, localPort: localPort, allowLan: allowLan)
                onNewItemAdded(newItem)
            } catch {
                showErrorDialog(error)
            }
        }
    }

    func reset() {
        address = item?.address ?? ""
        remotePort = item?.remotePort ?? .single(port: 0)
        localPort = item?.localPort
        allowLan = item?.allowLan ?? false
    }
}

#Preview {
    Group {
        ForwardedItemRow()
        ForwardedItemRow(item: ForwardedItemInfo(address: "192.168.1.1", remotePort: .single(port: 1234)))
        ForwardedItemRow(item: ForwardedItemInfo(address: "192.168.1.1", remotePort: .single(port: 1234), localPort: 4321))
        ForwardedItemRow(item: ForwardedItemInfo(address: "192.168.1.1", remotePort: .range(start: 1000, end: 2000)))
        ForwardedItemRow(item: ForwardedItemInfo(address: "192.168.1.1", remotePort: .range(start: 1000, end: 2000), localPort: 3000))
        ForwardedItemRow(item: ForwardedItemInfo(address: "192.168.1.1", remotePort: .single(port: 1234)), errors: [IpfError.addrInUse])
        ForwardedItemRow(item: ForwardedItemInfo(address: "192.168.1.1", remotePort: .single(port: 1234)), errors: [IpfError.addrInUse, IpfError.invalidLocalPortStart])
        ForwardedItemRow(item: ForwardedItemInfo(address: "www.google.com", remotePort: .single(port: 80), localPort: 8080))
    }
}
