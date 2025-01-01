import SwiftUI

struct RecordDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let record: BasketballRecord
    @State private var isEditing = false
    @State private var editedDate = Date()
    @State private var showingDatePicker = false
    
    var body: some View {
        List {
            Section {
                // 日期行
                HStack {
                    Label("日期", systemImage: "calendar")
                    Spacer()
                    if isEditing {
                        Button(action: { showingDatePicker = true }) {
                            Text(editedDate.formatted(date: .long, time: .shortened))
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text(record.wrappedDate.formatted(date: .long, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 比赛类型
                HStack {
                    Label("类型", systemImage: "figure.basketball")
                    Spacer()
                    Text(record.wrappedGameType)
                        .foregroundColor(.secondary)
                }
                
                // 时长
                HStack {
                    Label("时长", systemImage: "clock")
                    Spacer()
                    Text("\(record.duration) 分钟")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("感受") {
                // 强度
                HStack {
                    Label("强度", systemImage: "flame")
                    Spacer()
                    Text(String(repeating: "🔥", count: Int(record.intensity)))
                        .foregroundColor(.secondary)
                }
                
                // 疲劳度
                HStack {
                    Label("疲劳", systemImage: "battery.75")
                    Spacer()
                    Text(String(repeating: "💪", count: Int(record.fatigue)))
                        .foregroundColor(.secondary)
                }
            }
            
            if !record.wrappedNotes.isEmpty {
                Section("笔记") {
                    Text(record.wrappedNotes)
                        .foregroundColor(.secondary)
                }
            }
            
            if !record.tagArray.isEmpty {
                Section("标签") {
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
        }
        .navigationTitle("记录详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "保存" : "编辑") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(date: $editedDate, isPresented: $showingDatePicker)
        }
        .onAppear {
            editedDate = record.wrappedDate
        }
    }
    
    private func saveChanges() {
        record.date = editedDate
        
        do {
            try viewContext.save()
            print("成功更新记录日期")
        } catch {
            print("更新记录失败: \(error)")
        }
    }
}

// 日期选择器sheet
struct DatePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $date,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        RecordDetailView(record: PreviewData.shared.sampleRecords[0])
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 