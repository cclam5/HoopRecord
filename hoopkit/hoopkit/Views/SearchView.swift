import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 返回按钮
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.themeColor)
                        .imageScale(.large)
                }

                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("搜索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(red: 0.98, green: 0.96, blue: 0.94))
                .cornerRadius(14)
                .frame(height: 34)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.white)
            
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
                .background(Color.white)
            } else {
                SearchResultList(searchText: searchText)
                    .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .onAppear {
            isSearchFocused = true
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.themeColor)
            
            TextField("搜索记录", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.themeColor)
                }
            }
        }
        .padding()
    }
}

struct SearchResultList: View {
    @FetchRequest var records: FetchedResults<BasketballRecord>
    @State private var refreshID = UUID()
    @State private var showingDetail = false
    
    init(searchText: String) {
        _records = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
            predicate: NSPredicate(format: 
                "notes CONTAINS[cd] %@ OR gameType CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", 
                searchText, searchText, searchText)
        )
    }
    
    var body: some View {
        List {
            ForEach(records) { record in
                RecordRow(record: record, onUpdate: {
                    refreshID = UUID()
                }, parentShowingDetail: $showingDetail)
                .id(refreshID)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.white)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .background(Color.white)
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
