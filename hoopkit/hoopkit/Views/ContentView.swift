import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<BasketballRecord>
    
    @State private var showingNewRecord = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主列表视图
                List {
                    ForEach(records, id: \.wrappedId) { record in
                        NavigationLink(destination: RecordDetailView(record: record)) {
                            RecordRowView(record: record)
                        }
                    }
                    .onDelete(perform: deleteRecords)
                }
                .navigationTitle("打球记录")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: StatisticsView()) {
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SearchView()) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                
                // 添加记录按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingNewRecord = true }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 3)
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewRecord) {
            NewRecordView()
        }
    }
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            offsets.map { records[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("删除记录失败: \(error.localizedDescription)")
            }
        }
    }
}

// 记录行视图
struct RecordRowView: View {
    let record: BasketballRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.wrappedGameType)
                    .font(.headline)
                Spacer()
                Text(record.wrappedDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(record.wrappedNotes)
                .lineLimit(2)
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(record.tagArray, id: \.wrappedId) { tag in
                        Text(tag.wrappedName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
} 