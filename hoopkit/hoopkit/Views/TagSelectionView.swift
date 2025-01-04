import SwiftUI

struct TagSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<Tag>
    @State private var newTagName = ""
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField("新标签", text: $newTagName)
                        Button("添加") {
                            addTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                Section {
                    ForEach(tags) { tag in
                        HStack {
                            Text(tag.wrappedName)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themeColor)
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
                    .foregroundColor(.themeColor)
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let tag = Tag(context: viewContext)
        tag.id = UUID()
        tag.name = trimmedName
        
        do {
            try viewContext.save()
            selectedTags.insert(tag)
            newTagName = ""
        } catch {
            print("Error saving tag: \(error)")
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
} 