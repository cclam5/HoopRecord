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
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                List {
                    ForEach(records) { record in
                        NavigationLink(destination: RecordDetailView(record: record)) {
                            RecordRow(record: record)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteRecords)
                }
                .listStyle(.plain)
                
                // 添加按钮
                AddButton(showingNewRecord: $showingNewRecord)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: StatisticsView()) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
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
            try? viewContext.save()
        }
    }
}

// 记录行视图
struct RecordRow: View {
    let record: BasketballRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.wrappedGameType)
                    .font(.headline)
                Spacer()
                Text(record.wrappedDate.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Label("\(record.duration)分钟", systemImage: "clock")
                    .foregroundColor(.secondary)
                Label(String(repeating: "🔥", count: Int(record.intensity)),
                      systemImage: "flame")
                    .foregroundColor(.secondary)
            }
            
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
    }
}

// 添加按钮
struct AddButton: View {
    @Binding var showingNewRecord: Bool
    
    var body: some View {
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

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PreviewData.shared.context)
} 
