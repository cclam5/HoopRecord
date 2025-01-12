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
            ScrollView {
                VStack(spacing: 0) {
                    // 时间选择部分
                    VStack(spacing: 12) {
                        HStack {
                            Text("时间")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if isEditing {
                                DatePicker("", selection: $editedDate)
                                    .labelsHidden()
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            } else {
                                Text(record.wrappedDate.formatted(date: .abbreviated, time: .shortened))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Divider()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    // 上部分内容：紧凑布局
                    VStack(spacing: 12) {
                        typeAndIntensitySection
                        durationSection
                        Divider()
                    }
                    .padding()
                    
                    // 心得文本区域
                    notesSection
                        .frame(minHeight: 200) // 设置最小高度
                    
                    Divider()
                    
                    // 底部标签栏
                    tagSection
                }
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
        }
        .interactiveDismissDisabled(isEditing && hasUnsavedChanges)  // 禁用下滑关闭手势
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
    
    private var mainContent: some View {
        VStack(spacing: 12) {
            typeAndIntensitySection
            durationSection
            Divider()
            notesSection
        }
        .padding()
    }
    
    private var typeAndIntensitySection: some View {
        HStack {
            Text("类型")
                .foregroundColor(.secondary)
            
            if isEditing {
                gameTypeMenu
            } else {
                gameTypeText
            }
            
            Spacer()
            
            Text("强度")
                .foregroundColor(.secondary)
            intensityButtons
        }
    }
    
    private var gameTypeMenu: some View {
        Menu {
            ForEach(gameTypes, id: \.self) { type in
                Button(action: { editedGameType = type }) {
                    HStack {
                        Text(type)
                        if editedGameType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.themeColor)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(editedGameType)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var gameTypeText: some View {
        Text(record.wrappedGameType)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    private var intensityButtons: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                if isEditing {
                    Button(action: { editedIntensity = index }) {
                        intensityImage(for: index, isEditing: true)
                    }
                } else {
                    intensityImage(for: index, isEditing: false)
                }
            }
        }
    }
    
    private func intensityImage(for index: Int, isEditing: Bool) -> some View {
        let currentIntensity = isEditing ? editedIntensity : Int(record.intensity)
        return Image(systemName: index <= currentIntensity ? "flame.fill" : "flame")
            .foregroundColor(index <= currentIntensity ? .themeColor : .gray)
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("时长")
                Spacer()
                Text("\(isEditing ? Int(editedDuration) : Int(record.duration))分钟")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            if isEditing {
                VStack(spacing: 8) {
                    Slider(value: $editedDuration, in: 0...240, step: 1)
                        .accentColor(.themeColor)
                    
                    HStack(spacing: 8) {
                        ForEach([30, 60, 90, 120, 150, 180, 210], id: \.self) { mins in
                            Button(action: { editedDuration = Double(mins) }) {
                                Text("\(mins)")
                                    .font(.footnote)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(editedDuration == Double(mins) ? Color.themeColor : Color(.systemGray6))
                                    .foregroundColor(editedDuration == Double(mins) ? .white : .themeColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        Group {
            if isEditing {
                VStack {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if editedNotes.isEmpty {
                                    Text("记录今天的心得...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
                .padding()
            } else {
                VStack {
                    Text(record.wrappedNotes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .padding()
            }
        }
    }
    
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                // 标签输入框和建议列表
                VStack(alignment: .leading) {
                    TextField("输入标签名称，空格键添加", text: $newTagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: newTagName) { oldValue, newValue in
                            if newValue.last == " " {
                                addTagIfNeeded()
                            } else {
                                updateSuggestedTags(for: newValue)
                            }
                        }
                        .onSubmit {
                            addTagIfNeeded()
                        }
                    
                    // 建议标签列表
                    if !suggestedTags.isEmpty && !newTagName.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestedTags) { tag in
                                    Button(action: {
                                        selectSuggestedTag(tag)
                                    }) {
                                        Text(tag.wrappedName)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(15)
                                    }
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }
            }
            
            // 已选标签显示
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedTags)) { tag in
                            HStack {
                                Text(tag.wrappedName)
                                if isEditing {
                                    Button(action: {
                                        selectedTags.remove(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 12))
                                    }
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
        .sheet(isPresented: $showingTagSheet) {
            TagSelectionView(selectedTags: $selectedTags)
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
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    dismiss()
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
    
    // 更新建议标签列表
    private func updateSuggestedTags(for input: String) {
        guard !input.isEmpty else {
            suggestedTags = []
            return
        }
        
        let request = BasketballTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BasketballTag.name, ascending: true)]
        
        // 修改查询条件，使用 BEGINSWITH 而不是 CONTAINS
        request.predicate = NSPredicate(format: "name BEGINSWITH[cd] %@", input)
        
        do {
            let allMatchingTags = try viewContext.fetch(request)
            // 使用字典来去重，以标签名为键
            var uniqueTagsDict: [String: BasketballTag] = [:]
            for tag in allMatchingTags {
                uniqueTagsDict[tag.wrappedName] = tag
            }
            
            // 转换回数组并过滤已选择的标签
            suggestedTags = Array(uniqueTagsDict.values)
                .filter { !selectedTags.contains($0) }
                .sorted { $0.wrappedName < $1.wrappedName }
        } catch {
            print("Error fetching suggested tags: \(error)")
            suggestedTags = []
        }
    }
    
    // 选择建议标签
    private func selectSuggestedTag(_ tag: BasketballTag) {
        selectedTags.insert(tag)
        newTagName = ""
        suggestedTags = []
    }
}

#Preview {
    NavigationView {
        RecordDetailView(record: PreviewData.shared.sampleRecords[0])
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
