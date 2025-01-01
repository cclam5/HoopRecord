import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            
            if searchText.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                        .padding()
                    Text("输入关键词开始搜索")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                SearchResultList(searchText: searchText)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
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
            ForEach(records) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordRow(record: record)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .overlay(Group {
            if records.isEmpty {
                Text("未找到相关记录")
                    .foregroundColor(.secondary)
            }
        })
    }
}

#Preview {
    NavigationView {
        SearchView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
