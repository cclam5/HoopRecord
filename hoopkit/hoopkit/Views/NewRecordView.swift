import SwiftUI
import CoreData

struct NewRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    private let gameTypes = ["个人训练", "队内训练", "1v1", "2v2", "3v3", "4v4", "5v5"]
    
    @State private var gameType = "个人训练"
    @State private var duration: Double = 60
    @State private var intensity = 3
    @State private var notes = ""
    @State private var showingTagSheet = false
    @State private var selectedTags: Set<Tag> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 内容区域
                ScrollView {
                    VStack(spacing: 0) {
                        // 类型和强度部分
                        VStack(spacing: 16) {
                            // 类型和强度放在同一行
                            HStack {
                                Text("类型")
                                    .foregroundColor(.secondary)
                                
                                Menu {
                                    ForEach(gameTypes, id: \.self) { type in
                                        Button(action: { gameType = type }) {
                                            HStack {
                                                Text(type)
                                                if gameType == type {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.themeColor)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(gameType)
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                Text("强度")
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { index in
                                        Button(action: { intensity = index }) {
                                            Image(systemName: index <= intensity ? "flame.fill" : "flame")
                                                .foregroundColor(index <= intensity ? .themeColor : .gray)
                                        }
                                    }
                                }
                            }
                            
                            // 时长滑动条
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("时长")
                                    Spacer()
                                    Text("\(Int(duration))分钟")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $duration,
                                       in: 15...240,
                                       step: 15)
                                            .accentColor(.themeColor)
                                        
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach([30, 60, 90, 120], id: \.self) { mins in
                                            Button(action: { duration = Double(mins) }) {
                                                Text("\(mins)")
                                                    .font(.footnote)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(duration == Double(mins) ? Color.themeColor : Color(.systemGray6))
                                                    .foregroundColor(duration == Double(mins) ? .white : .primary)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        // 心得部分
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .overlay(
                                Group {
                                    if notes.isEmpty {
                                        Text("记录今天的心得...")
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                            .padding(.top, 8)
                                    }
                                },
                                alignment: .topLeading
                            )
                            .padding()
                        
                        Divider()
                        
                        // 标签部分
                        VStack(alignment: .leading, spacing: 12) {
                            if selectedTags.isEmpty {
                                Button(action: { showingTagSheet = true }) {
                                    HStack {
                                        Image(systemName: "tag")
                                        Text("添加标签")
                                    }
                                    .foregroundColor(.themeColor)
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(selectedTags)) { tag in
                                            HStack {
                                                Text(tag.wrappedName)
                                                Button(action: { selectedTags.remove(tag) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(15)
                                        }
                                        
                                        Button(action: { showingTagSheet = true }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.themeColor)
                                        }
                                        .padding(.leading, 4)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("新记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.themeColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .foregroundColor(.themeColor)
                }
            }
        }
        .sheet(isPresented: $showingTagSheet) {
            TagSelectionView(selectedTags: $selectedTags)
        }
    }
    
    private func saveRecord() {
        withAnimation {
            let newRecord = BasketballRecord(context: viewContext)
            newRecord.id = UUID()
            newRecord.gameType = gameType
            newRecord.date = Date()
            newRecord.duration = Int16(duration)
            newRecord.intensity = Int16(intensity)
            newRecord.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let tagSet = NSSet(array: Array(selectedTags))
            newRecord.tags = tagSet
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Error saving record: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        NewRecordView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
