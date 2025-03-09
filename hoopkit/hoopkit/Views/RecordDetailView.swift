import SwiftUI

struct RecordDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
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
    @State private var showingDeleteAlert = false  // 添加删除确认提示的状态
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var showingShareView = false  // 添加状态变量
    
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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // 时间选择部分
                        VStack(spacing: ViewStyles.defaultPadding) {
                            HStack {
                                Text("时间")
                                    .font(ViewStyles.labelFont)
                                    .foregroundColor(.customSecondaryText)
                                
                                Spacer()
                                
                                if isEditing {
                                    DatePicker("", selection: $editedDate)
                                        .font(ViewStyles.labelFont)
                                        .labelsHidden()
                                        .fixedSize()
                                        .scaleEffect(0.7)
                                        .frame(width: 155, height: 30)
                                        .cornerRadius(ViewStyles.cornerRadius)
                                } else {
                                    Text(record.wrappedDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(ViewStyles.labelFont)
                                        .foregroundColor(.customPrimaryText)
                                        .padding(.horizontal, ViewStyles.defaultPadding)
                                        .padding(.vertical, ViewStyles.smallPadding)
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
                    Button(action: {
                        if isEditing {
                            if hasUnsavedChanges {
                                showingDiscardAlert = true
                            } else {
                                withAnimation {
                                    isEditing = false
                                }
                            }
                        } else {
                            showingDeleteAlert = true
                        }
                    }) {
                        Image(systemName: isEditing ? "xmark" : "trash")
                            .font(.system(size: 13))
                            .foregroundColor(isEditing ? .customSecondaryText : .red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isEditing ? 
                                Color.customListBackground : 
                                Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !isEditing {
                            Button(action: { showingShareView = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13))
                                    .foregroundColor(.customSecondaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.customListBackground)
                                    .cornerRadius(6)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isEditing = true
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13))
                                    .foregroundColor(.customSecondaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.customListBackground)
                                    .cornerRadius(6)
                            }
                        } else {
                            Button(action: {
                                saveChanges()
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13))
                                    .foregroundColor(.checkmarkColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.customBrandPrimary.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.customBackground)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
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
        .alert("删除记录", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条记录吗？此操作无法撤销。")
        }
        .interactiveDismissDisabled(isEditing && hasUnsavedChanges)
        .alert("操作失败", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingShareView) {
            ShareRecordView(record: record)
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: ViewStyles.defaultPadding) {
            typeAndIntensityView
            durationView
            Divider()
                .background(Color.customListBackground)
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
                    .foregroundColor(.customSecondaryText)
                Text(record.gameType ?? "")
                    .font(ViewStyles.labelFont)
                    .foregroundColor(.customPrimaryText)
                    .padding(.horizontal, ViewStyles.defaultPadding)
                    .padding(.vertical, ViewStyles.smallPadding)
                    .cornerRadius(ViewStyles.cornerRadius)
            }
            
            Spacer()
            
            if isEditing {
                IntensityControl(intensity: $editedIntensity, isEditing: true)
            } else {
                IntensityControl(intensity: .constant(Int(record.intensity)), isEditing: false)
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
                    .foregroundColor(.customPrimaryText)
            } else {
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.customPrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(ViewStyles.smallPadding)
                } else {
                    Text("未填写心得")
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.customSecondaryText)
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
                    .foregroundColor(.customPrimaryText)
            } else {
                if !record.tagArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ViewStyles.smallPadding) {
                            ForEach(record.tagArray) { tag in
                                Text(tag.wrappedName)
                                    .font(ViewStyles.labelFont)
                                    .foregroundColor(.customPrimaryText)
                                    .padding(.horizontal, ViewStyles.defaultPadding)
                                    .padding(.vertical, ViewStyles.smallPadding)
                                    .background(Color.customListBackground)
                                    .cornerRadius(ViewStyles.cornerRadius)

                            }
                        }
                    }
                } else {
                    Text("未添加标签")
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.customSecondaryText)
                        .padding(.vertical, ViewStyles.smallPadding)
                }
            }
        }
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
        withAnimation {
            do {
                // 更新记录的值
                record.gameType = editedGameType
                record.duration = Int16(editedDuration)
                record.intensity = Int16(editedIntensity)
                record.notes = editedNotes
                record.date = editedDate
                record.tags = NSSet(array: Array(selectedTags))
                
                // 保存更改
                try viewContext.save()
                HapticManager.success()
                isEditing = false
            } catch {
                HapticManager.error()
                showingError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // 添加删除记录的方法
    private func deleteRecord() {
        viewContext.delete(record)
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    NavigationView {
        RecordDetailView(record: PreviewData.shared.sampleRecords[0])
            .environment(\.managedObjectContext, PreviewData.shared.context)
            .environmentObject(ThemeManager.shared)
    }
} 
