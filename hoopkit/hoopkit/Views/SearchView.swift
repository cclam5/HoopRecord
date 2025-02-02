import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var searchHistory: [String] = []  // 改为 State
    
    // 从 UserDefaults 加载搜索历史
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "searchHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = history
        }
    }
    
    // 保存搜索历史到 UserDefaults
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "searchHistory")
        }
    }
    
    // 添加搜索记录
    private func addSearchHistory(_ text: String) {
        guard !text.isEmpty else { return }
        // 如果已存在相同的搜索词，先移除它
        searchHistory.removeAll { $0 == text }
        // 将新的搜索词添加到最前面
        searchHistory.insert(text, at: 0)
        // 保持最多10条记录
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }
        // 保存更新后的历史记录
        saveSearchHistory()
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.customBrandPrimary)
                        .imageScale(.medium)
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.customSecondaryText)
                        .font(.system(size: 14))
                    
                    TextField("搜索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .foregroundColor(.customPrimaryText)
                        .focused($isSearchFocused)
                        .onSubmit {
                            addSearchHistory(searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.customSecondaryText)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.customListBackground)
                .cornerRadius(14)
                .frame(height: 32)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .background(Color.customBackground)
            
            if searchText.isEmpty {
                if !searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("最近搜索")
                                .font(.subheadline)
                                .foregroundColor(.customSecondaryText)
                            
                            Spacer()
                            
                            Button(action: { 
                                searchHistory.removeAll()
                                saveSearchHistory()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.customSecondaryText)
                                    .imageScale(.small)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(searchHistory, id: \.self) { history in
                                    Button(action: {
                                        searchText = history
                                        addSearchHistory(history)
                                    }) {
                                        Text(history)
                                            .font(.subheadline)
                                            .foregroundColor(.customPrimaryText)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.customListBackground)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                Spacer()
            } else {
                SearchResultList(searchText: searchText)
            }
        }
        .navigationBarHidden(true)
        .background(Color.customBackground)
        .onAppear {
            isSearchFocused = true
            loadSearchHistory()
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

struct SearchResultList: View {
    @FetchRequest var records: FetchedResults<BasketballRecord>
    @State private var refreshID = UUID()
    
    init(searchText: String) {
        _records = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
            predicate: NSPredicate(format: 
                "notes CONTAINS[cd] %@ OR gameType CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", 
                searchText, searchText, searchText)
        )
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(records) { record in
                    RecordRow(record: record, onUpdate: {
                        refreshID = UUID()
                    })
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 14)
        }
        .background(Color.customBackground)
        .overlay {
            if records.isEmpty {
                Text("未找到相关记录")
                    .foregroundColor(.customSecondaryText)
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
