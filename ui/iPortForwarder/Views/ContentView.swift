import SwiftUI

struct ContentView: View {
    @State private var items: [ForwardedItem] = [ForwardedItem]()

    @State private var isAddingNew = false

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    ForEach(self.items.indices, id: \.self) { index in
                        ForwardedItemRow(item: self.items[index], onChange: { ipAddress, rule, allowLan in
                            items[index] = ForwardedItem(ip: ipAddress, rule: rule, allowLan: allowLan)
                        })
                        .contextMenu {
                            Button(action: {
                                items.remove(at: index)
                            }) {
                                Text("Delete")
                            }
                        }
                    }
                    .onDelete(perform: { indexSet in
                        items.remove(atOffsets: indexSet)
                    })
                    if isAddingNew {
                        ForwardedItemRow(onNewItemAdded: { newItem in
                            items.append(newItem)
                            isAddingNew = false
                        }, onCancel: { withAnimation {
                            isAddingNew = false
                        } })
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                // A hack to make ScrollView stable
                if items.isEmpty {
                    HStack {
                        Spacer()
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 100)
            .padding()

            if !isAddingNew {
                Button("Add New") {
                    withAnimation {
                        isAddingNew = true
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
