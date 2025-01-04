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
    @State private var selectedTags = Set<BasketballTag>()
    @State private var newTagName: String = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            NavigationView {
                VStack(spacing: 0) {
                    // 上部分内容：紧凑布局
                    VStack(spacing: 12) {  // 减小间距
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
                                   in: 0...240,
                                   step: 1)
                                                .accentColor(.themeColor)
                                            
                            HStack(spacing: 8) {
                                ForEach([30, 60, 90, 120, 150, 180, 210], id: \.self) { mins in
                                    Button(action: { duration = Double(mins) }) {
                                        Text("\(mins)")
                                            .font(.footnote)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(duration == Double(mins) ? Color.themeColor : Color(.systemGray6))
                                            .foregroundColor(duration == Double(mins) ? .white : .themeColor)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        // 心得文本框
                        ScrollView {
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
                        }
                        .frame(maxHeight: 150)
                    }
                    .padding()
                    
                    Spacer()  // 添加弹性空间
                    
                    Divider()
                    
                    // 底部标签栏
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("输入标签名称，空格键添加", text: $newTagName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    addTagIfNeeded()
                                }
                                .onChange(of: newTagName) { oldValue, newValue in
                                    if newValue.last == " " {
                                        addTagIfNeeded()
                                    }
                                }
                        }
                        
                        if !selectedTags.isEmpty {
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
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all)
                )
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
            .frame(width: 400, height: 600)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .ignoresSafeArea()
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
    
    private func addTagIfNeeded() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            newTagName = ""
            return
        }
        
        // 检查是否已存在该标签
        let request = BasketballTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", trimmedName)
        
        do {
            let existingTags = try viewContext.fetch(request)
            if let existingTag = existingTags.first {
                selectedTags.insert(existingTag)
            } else {
                let newTag = BasketballTag(context: viewContext)
                newTag.id = UUID()
                newTag.name = trimmedName
                try viewContext.save()
                selectedTags.insert(newTag)
            }
            newTagName = ""
        } catch {
            print("Error adding tag: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        NewRecordView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
