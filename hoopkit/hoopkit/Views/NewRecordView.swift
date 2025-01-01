import SwiftUI

struct NewRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var gameType = "5v5"
    @State private var duration = 60
    @State private var intensity = 3
    @State private var fatigue = 3
    @State private var notes = ""
    @State private var tags = ""
    
    let gameTypes = ["5v5", "3v3", "1v1", "投篮练习"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    Picker("比赛类型", selection: $gameType) {
                        ForEach(gameTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    
                    Stepper("时长: \(duration)分钟", value: $duration, in: 15...240, step: 15)
                }
                
                Section(header: Text("感受")) {
                    VStack {
                        Text("运动强度: \(intensity)")
                        Slider(value: .init(get: {
                            Double(intensity)
                        }, set: { newValue in
                            intensity = Int(newValue)
                        }), in: 1...5, step: 1)
                    }
                    
                    VStack {
                        Text("疲惫程度: \(fatigue)")
                        Slider(value: .init(get: {
                            Double(fatigue)
                        }, set: { newValue in
                            fatigue = Int(newValue)
                        }), in: 1...5, step: 1)
                    }
                }
                
                Section(header: Text("心得")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                    
                    TextField("添加标签（用逗号分隔）", text: $tags)
                }
            }
            .navigationTitle("新建记录")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("保存") { saveRecord() }
            )
        }
    }
    
    private func saveRecord() {
        let record = BasketballRecord.create(
            in: viewContext,
            gameType: gameType,
            duration: Int16(duration),
            intensity: Int16(intensity),
            fatigue: Int16(fatigue),
            notes: notes
        )
        
        // 处理标签
        let tagArray = tags.split(separator: ",").map(String.init)
        for tagName in tagArray {
            let tag = BasketballTag.create(
                in: viewContext,
                name: tagName.trimmingCharacters(in: .whitespaces)
            )
            record.addToTags(tag)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("保存记录失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationView {
        NewRecordView()
            .environment(\.managedObjectContext, PreviewData.shared.context)
    }
} 
