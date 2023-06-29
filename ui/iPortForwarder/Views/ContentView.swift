import SwiftUI

struct ContentView: View {
    @EnvironmentObject var globalState: GlobalState

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    ForEach(globalState.items) { item in
                        ForwardedItemRow(
                            item: item,
                            errors: globalState.errors[item.id],
                            onChange: { ipAddress, remotePort, localPort, allowLan in
                                let index = globalState.items.firstIndex(where: { $0 === item })!
                                globalState.items[index].destory()
                                do {
                                    globalState.errors.removeValue(forKey: item.id)
                                    let newItem = try ForwardedItem(ip: ipAddress, remotePort: remotePort, localPort: localPort, allowLan: allowLan)
                                    withAnimation {
                                        globalState.items[index] = newItem
                                    }
                                } catch {
                                    showIpfError(error)
                                }
                            },
                            onDelete: {
                                let index = globalState.items.firstIndex(where: { $0 === item })
                                withAnimation {
                                    globalState.items.remove(at: index!)
                                    globalState.errors.removeValue(forKey: item.id)
                                }
                            }
                        )
                        .contextMenu {
                            Button(action: {
                                let index = globalState.items.firstIndex(where: { $0 === item })
                                withAnimation {
                                    globalState.items.remove(at: index!)
                                    globalState.errors.removeValue(forKey: item.id)
                                }
                            }) {
                                Text("Delete")
                            }
                        }
                    }

                    if globalState.isAddingNewItem {
                        ForwardedItemRow(onNewItemAdded: { newItem in
                            globalState.items.append(newItem)
                            globalState.isAddingNewItem = false
                        }, onCancel: { withAnimation {
                            globalState.isAddingNewItem = false
                        } })
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                // A hack to make ScrollView stable
                if globalState.items.isEmpty {
                    HStack {
                        Spacer()
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 100)
            .padding(.all, 8)

            if !globalState.isAddingNewItem {
                Button("Add New") {
                    withAnimation {
                        globalState.isAddingNewItem = true
                    }
                }
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
