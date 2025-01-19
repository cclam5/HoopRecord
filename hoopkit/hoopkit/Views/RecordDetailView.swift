import SwiftUI

struct RecordDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingTagSheet = false
    @State private var selectedTags: Set<BasketballTag>
    @State private var newTagName = ""
    
    // 编辑状态的临时变量
    @State private var editedGameType: String
    @State private var editedDuration: Double
    @State private var editedIntensity: Int
    @State private var editedNotes: String
    
    // 添加时间编辑状态
    @State private var editedDate: Date
    
    private let gameTypes = ["个人训练", "队内训练", "1v1", "2v2", "3v3", "4v4", "5v5"]
    let record: BasketballRecord
    
    @State private var suggestedTags: [BasketballTag] = []  // 添加建议标签数组
    
    @State private var showingDiscardAlert = false
    
    init(record: BasketballRecord) {
        self.record = record
        _editedGameType = State(initialValue: record.gameType ?? "")
        _editedDuration = State(initialValue: Double(record.duration))
        _editedIntensity = State(initialValue: Int(record.intensity))
        _editedNotes = State(initialValue: record.notes ?? "")
        _selectedTags = State(initialValue: Set(record.tagArray))
        _editedDate = State(initialValue: record.date ?? Date())  // 初始化时间
    }
    
    private var hasUnsavedChanges: Bool {
        if isEditing {
            return editedGameType != record.gameType ||
                   editedDuration != Double(record.duration) ||
                   editedIntensity != Int(record.intensity) ||
                   editedNotes != (record.notes ?? "") ||
                   editedDate != (record.date ?? Date()) ||
                   selectedTags != Set(record.tagArray)
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {  // 使用 VStack 作为根容器
                ScrollView {
                    VStack(spacing: 0) {
                        // 时间选择部分
                        VStack(spacing: ViewStyles.defaultPadding) {
                            HStack {
                                Text("时间")
                                    .font(ViewStyles.labelFont)
                                    .foregroundColor(ViewStyles.labelColor)
                                
                                Spacer()
                                
                                if isEditing {
                                    DatePicker("", selection: $editedDate)
                                        .font(ViewStyles.labelFont)
                                        .labelsHidden()
                                        .fixedSize()
                                        .scaleEffect(0.8)  // 缩小 DatePicker 的整体大小
                                        .frame(width: 155, height: 30)  // 限制宽高
                                        .background(ViewStyles.backgroundColor)
                                        .cornerRadius(ViewStyles.cornerRadius)
                                } else {
                                    Text(record.wrappedDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(ViewStyles.labelFont)
                                        .padding(.horizontal, ViewStyles.defaultPadding)
                                        .padding(.vertical, ViewStyles.smallPadding)
                                        .background(ViewStyles.backgroundColor)
                                        .cornerRadius(ViewStyles.cornerRadius)
                                }
                            }
                        }
                        .padding(.horizontal)
                        // .padding(.bottom)
                        
                        // 主要内容区域
                        mainContentView
                    }
                }
                
                Divider()  // 添加分隔线
                
                // 标签部分固定在底部
                tagInputView
                    .padding(.horizontal)
                    .padding(.vertical, ViewStyles.smallPadding)
            }
            .navigationTitle("记录详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "取消" : "返回") {
                        if isEditing && hasUnsavedChanges {
                            showingDiscardAlert = true
                        } else {
                            if isEditing {
                                isEditing = false
                            } else {
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(.themeColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "编辑") {
                        if isEditing {
                            saveChanges()
                        }
                        isEditing.toggle()
                    }
                    .foregroundColor(.themeColor)
                }
            }
        }
        .alert("放弃更改", isPresented: $showingDiscardAlert) {
            Button("继续编辑", role: .cancel) { }
            Button("放弃", role: .destructive) {
                isEditing = false
                // 重置所有编辑状态
                editedGameType = record.gameType ?? ""
                editedDuration = Double(record.duration)
                editedIntensity = Int(record.intensity)
                editedNotes = record.notes ?? ""
                editedDate = record.date ?? Date()
                selectedTags = Set(record.tagArray)
            }
        } message: {
            Text("当前更改尚未保存，确定要放弃吗？")
        }
        .interactiveDismissDisabled(isEditing && hasUnsavedChanges)
    }
    
    private func handleDismiss() {
        if isEditing && hasUnsavedChanges {
            showingDiscardAlert = true
        } else {
            if isEditing {
                isEditing = false
            } else {
                dismiss()
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: ViewStyles.defaultPadding) {
            typeAndIntensityView
            durationView
            Divider()
            notesView
        }
        .padding()
    }
    
    private var typeAndIntensityView: some View {
        HStack {
            if isEditing {
                GameTypeSelector(gameTypes: gameTypes, selectedType: $editedGameType)
            } else {
                Text("类型")
                    .font(ViewStyles.labelFont)
                    .foregroundColor(ViewStyles.labelColor)
                Text(record.gameType ?? "")
                    .font(ViewStyles.labelFont)
            }
            
            Spacer()
            
            if isEditing {
                IntensityControl(intensity: $editedIntensity)
            } else {
                Text("强度")
                    .font(ViewStyles.labelFont)
                    .foregroundColor(ViewStyles.labelColor)
                HStack(spacing: ViewStyles.tinyPadding) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= record.intensity ? "flame.fill" : "flame")
                            .font(ViewStyles.labelFont)
                            .foregroundColor(index <= record.intensity ? .themeColor : .gray)
                    }
                }
            }
        }
    }
    
    private var durationView: some View {
        DurationSelector(
            duration: $editedDuration,
            presets: [30, 60, 90, 120, 150, 180, 210],
            isEditing: isEditing
        )
    }
    
    private var notesView: some View {
        VStack(alignment: .leading) {
            if isEditing {
                NotesEditor(notes: $editedNotes)
            } else {
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(ViewStyles.smallPadding)
                } else {
                    Text("未填写心得")
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(ViewStyles.smallPadding)
                }
            }
        }
    }
    
    private var tagInputView: some View {
        VStack(alignment: .leading) {
            if isEditing {
                TagInput(
                    newTagName: $newTagName,
                    selectedTags: $selectedTags,
                    onSubmit: addTagIfNeeded
                )
            } else {
                if !record.tagArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ViewStyles.smallPadding) {
                            ForEach(record.tagArray) { tag in
                                Text(tag.wrappedName)
                                    .font(ViewStyles.labelFont)
                                    .padding(.horizontal, ViewStyles.defaultPadding)
                                    .padding(.vertical, ViewStyles.smallPadding)
                            }
                        }
                    }
                } else {
                    Text("未设置标签")
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.secondary)
                        .padding(.vertical, ViewStyles.smallPadding)
                }
            }
        }
        // .padding(.vertical, ViewStyles.smallPadding)
    }
    
    private func addTagIfNeeded() {
        let tagName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tagName.isEmpty {
            // 检查是否已存在同名标签
            let request = BasketballTag.fetchRequest()
            request.predicate = NSPredicate(format: "name ==[cd] %@", tagName)
            
            do {
                let existingTags = try viewContext.fetch(request)
                if let existingTag = existingTags.first {
                    // 如果存在同名标签，使用已有的
                    selectedTags.insert(existingTag)
                } else {
                    // 如果不存在，创建新标签
                    let tag = BasketballTag(context: viewContext)
                    tag.id = UUID()
                    tag.name = tagName
                    selectedTags.insert(tag)
                }
            } catch {
                print("Error checking existing tags: \(error)")
            }
            
            newTagName = ""
            suggestedTags = []
        }
    }
    
    private func saveChanges() {
        record.gameType = editedGameType
        record.duration = Int16(editedDuration)
        record.intensity = Int16(editedIntensity)
        record.notes = editedNotes
        record.date = editedDate  // 保存编辑后的时间
        record.tags = NSSet(array: Array(selectedTags))
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
        
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    NavigationView {
        RecordDetailView(record: PreviewData.shared.sampleRecords[0])
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
