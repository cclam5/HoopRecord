import SwiftUI
import CoreData

struct TagSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<BasketballTag>
    
    @State private var newTagName: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var tags: [BasketballTag] = []
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("输入标签名称，空格键添加", text: $newTagName)
                        .onSubmit {
                            addTagIfNeeded()
                        }
                        .onChange(of: newTagName) { oldValue, newValue in
                            if newValue.last == " " {
                                addTagIfNeeded()
                            }
                        }
                }
                
                Section {
                    ForEach(tags) { tag in
                        HStack {
                            Text(tag.wrappedName)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.checkmarkColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTag(tag)
                        }
                    }
                }
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadTags()
            }
        }
    }
    
    private func loadTags() {
        let request = BasketballTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BasketballTag.name, ascending: true)]
        
        do {
            tags = try viewContext.fetch(request)
        } catch {
            errorMessage = "加载标签失败：\(error.localizedDescription)"
            showError = true
        }
    }
    
    private func addTagIfNeeded() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            newTagName = ""
            return
        }
        
        // 检查重复
        if tags.contains(where: { $0.name == trimmedName }) {
            errorMessage = "已存在相同名称的标签"
            showError = true
            newTagName = ""
            return
        }
        
        // 创建新标签
        let newTag = BasketballTag(context: viewContext)
        newTag.name = trimmedName
        newTag.id = UUID()
        
        do {
            try viewContext.save()
            newTagName = ""
            loadTags()
        } catch {
            errorMessage = "保存标签失败：\(error.localizedDescription)"
            showError = true
        }
    }
    
    private func toggleTag(_ tag: BasketballTag) {
        withAnimation {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }
    }
} 
