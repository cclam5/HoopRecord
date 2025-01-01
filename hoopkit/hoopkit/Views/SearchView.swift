import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            
            if searchText.isEmpty {
                Text("输入关键词开始搜索")
                    .foregroundColor(.secondary)
            } else {
                SearchResultList(searchText: searchText)
            }
        }
        .navigationTitle("搜索")
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索记录", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct SearchResultList: View {
    @FetchRequest var records: FetchedResults<BasketballRecord>
    
    init(searchText: String) {
        _records = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
            predicate: NSPredicate(format: "notes CONTAINS[cd] %@ OR gameType CONTAINS[cd] %@", 
                                 searchText, searchText)
        )
    }
    
    var body: some View {
        List {
            ForEach(records, id: \.wrappedId) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordRowView(record: record)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SearchView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 