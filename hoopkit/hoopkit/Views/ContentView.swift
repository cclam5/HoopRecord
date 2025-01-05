import SwiftUI
import CoreData

// 定义全局主题色
extension Color {
    static let themeColor = Color(red: 0, green: 0.3, blue: 0)  // 使用深森林绿
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<BasketballRecord>
    
    @State private var showingNewRecord = false
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    
    // 按月份分组的记录
    var groupedRecords: [String: [BasketballRecord]] {
        Dictionary(grouping: records) { record in
            let date = record.wrappedDate
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: date)
        }
    }
    
    // 排序后的月份键
    var sortedMonths: [String] {
        groupedRecords.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 工具栏背景
                HStack {
                    NavigationLink(destination: StatisticsView()
                        .navigationBarBackButtonHidden(true)
                    ) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.themeColor)
                            .imageScale(.large)
                    }
                    
                    Spacer()
                    
                    // 中间的篮球图标
                    Image(systemName: "basketball")
                        .foregroundColor(.themeColor)
                        .imageScale(.large)
                    
                    Spacer()
                    
                    NavigationLink(destination: SearchView()
                        .navigationBarBackButtonHidden(true)
                    ) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.themeColor)
                            .imageScale(.large)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
                
                // 记录列表和滚动条
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    GeometryReader { geometry in
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                ForEach(sortedMonths, id: \.self) { month in
                                    Section(header: monthHeader(month)) {
                                        VStack(spacing: 12) {
                                            ForEach(groupedRecords[month] ?? []) { record in
                                                RecordRow(record: record)
                                                    .padding(.horizontal)
                                            }
                                        }
                                        .padding(.vertical)
                                    }
                                }
                            }
                            .background(GeometryReader { contentGeometry in
                                Color.clear.preference(key: ContentHeightKey.self,
                                                     value: contentGeometry.size.height)
                            })
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ContentHeightKey.self) { height in
                            contentHeight = height
                        }
                        .overlay(
                            ScrollIndicator(
                                contentHeight: contentHeight,
                                viewportHeight: geometry.size.height,
                                scrollOffset: scrollOffset
                            )
                            .padding(.trailing, 2),
                            alignment: .trailing
                        )
                    }
                    
                    // 底部添加按钮
                    VStack {
                        Spacer()
                        Button(action: { showingNewRecord = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.themeColor)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(.bottom, 16)
                    }
                }

            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingNewRecord) {
            NewRecordView()
        }
    }
    
    // 月份标题视图
    private func monthHeader(_ month: String) -> some View {
        HStack {
            Text(month)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(.systemGroupedBackground).opacity(0.9))
    }
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            offsets.map { records[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

// 记录行视图
struct RecordRow: View {
    let record: BasketballRecord
    @State private var showingDetail = false
    
    private var durationInHours: String {
        let hours = Double(record.duration) / 60.0
        return String(format: "%.1f小时", hours)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. 类型和时间
            HStack {
                Text(record.wrappedGameType)
                    .font(.headline)
                Spacer()
                
                Text(record.wrappedDate.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
                
                Button(action: { showingDetail = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.themeColor)
                        .imageScale(.large)
                }
            }
            
            // 2. 时长和强度
            HStack(spacing: 12) {
                Label(durationInHours, systemImage: "clock")
                    .foregroundColor(.secondary)
                Label(String(repeating: "🔥", count: Int(record.intensity)),
                      systemImage: "flame")
                    .foregroundColor(.secondary)
            }
            
            // 3. 心得（如果有）
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.vertical, 2)
            }
            
            // 4. 标签（如果有）
            if !record.tagArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(record.tagArray) { tag in
                            Text(tag.wrappedName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                RecordDetailView(record: record)
            }
        }
    }
}

// 自定义滚动条指示器
struct ScrollIndicator: View {
    let contentHeight: CGFloat
    let viewportHeight: CGFloat
    let scrollOffset: CGFloat
    
    private var indicatorHeight: CGFloat {
        let ratio = viewportHeight / contentHeight
        return max(30, viewportHeight * ratio)
    }
    
    private var indicatorOffset: CGFloat {
        let maxOffset = viewportHeight - indicatorHeight
        let ratio = scrollOffset / (contentHeight - viewportHeight)
        return maxOffset * ratio
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.5))
            .frame(width: 6, height: indicatorHeight)
            .offset(y: indicatorOffset)
    }
}

// 用于获取内容高度的 PreferenceKey
struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PreviewData.shared.context)
} 

