import SwiftUI
import CoreData

struct NewRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 将 gameTypes 移到外部
    private let gameTypes = ["个人训练", "队内训练", "1v1", "2v2", "3v3", "4v4", "5v5"]
    private let durationPresets = [30, 60, 90, 120, 150, 180, 210]
    
    // 状态变量
    @State private var gameType = "个人训练"
    @State private var duration: Double = 60
    @State private var intensity = 3
    @State private var notes = ""
    @State private var showingTagSheet = false
    @State private var selectedTags = Set<BasketballTag>()
    @State private var newTagName = ""
    @State private var showingDiscardAlert = false
    @State private var showingSaveConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // 添加初始值常量
    private let initialGameType = "个人训练"
    private let initialDuration: Double = 60
    private let initialIntensity = 3
    
    init() {
        // 设置初始状态
        _gameType = State(initialValue: initialGameType)
        _duration = State(initialValue: initialDuration)
        _intensity = State(initialValue: initialIntensity)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainContentView
                Spacer()
                Divider()
                tagInputView
                    .padding(.horizontal)
                    .padding(.vertical, ViewStyles.smallPadding)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("新记录")
                        .font(.headline)
                }
                toolbarContent
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .interactiveDismissDisabled(hasUnsavedContent)
        .alert("放弃编辑", isPresented: $showingDiscardAlert) {
            Button("继续编辑", role: .cancel) { }
            Button("放弃", role: .destructive) { dismiss() }
        } message: {
            Text("当前记录尚未保存，确定要放弃吗？")
        }
    }
    
    // MARK: - 子视图
    
    private var mainContentView: some View {
        VStack(spacing: 12) {
            typeAndIntensityView
            durationView
            Divider()
            notesView
        }
        .padding()
    }
    
    private var typeAndIntensityView: some View {
        HStack {
            GameTypeSelector(gameTypes: gameTypes, selectedType: $gameType)
            Spacer()
            IntensityControl(intensity: $intensity)
        }
    }
    
    private var durationView: some View {
        DurationSelector(duration: $duration, presets: durationPresets)
    }
    
    private var notesView: some View {
        NotesEditor(notes: $notes)
    }
    
    private var tagInputView: some View {
        VStack(alignment: .leading) {
            TagInput(
                newTagName: $newTagName,
                selectedTags: $selectedTags,
                onSubmit: addTagIfNeeded
            )
        }
    }
    
    // MARK: - 工具栏
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    if hasUnsavedContent {
                        showingDiscardAlert = true
                    } else {
                        dismiss()
                    }
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
    
    // MARK: - 功能方法
    
    private func saveRecord() {
        withAnimation {
            let newRecord = BasketballRecord(context: viewContext)
            newRecord.id = UUID()
            newRecord.gameType = gameType
            newRecord.date = Date()
            newRecord.duration = Int16(duration)
            newRecord.intensity = Int16(intensity)
            newRecord.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            newRecord.tags = NSSet(array: Array(selectedTags))
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                showingError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addTagIfNeeded() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            newTagName = ""
            return
        }
        
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
            showingError = true
            errorMessage = "添加标签失败：\(error.localizedDescription)"
        }
    }
    
    private var hasUnsavedContent: Bool {
        // 检查所有可能的更改
        return !notes.isEmpty || 
               !selectedTags.isEmpty ||
               gameType != initialGameType ||
               duration != initialDuration ||
               intensity != initialIntensity
    }
}

#Preview {
    NavigationView {
        NewRecordView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
