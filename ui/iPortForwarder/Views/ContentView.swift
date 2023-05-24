import SwiftUI

struct ContentView: View {
    @State private var items: [ForwardedItem] = [ForwardedItem]()

    @State private var isAddingNew = false

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        ForwardedItemRow(item: item, onChange: { ipAddress, port, allowLan in
                            items[index] = ForwardedItem(source: ipAddress, port: port, allowLan: allowLan)
                        })
                    }
                    if isAddingNew {
                        ForwardedItemRow(onNewItemAdded: { newItem in
                            items.append(newItem)
                            isAddingNew = false
                        }, onCancel: { isAddingNew = false })
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 100)

            if !isAddingNew {
                Button("Add New") {
                    isAddingNew = true
                }
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
