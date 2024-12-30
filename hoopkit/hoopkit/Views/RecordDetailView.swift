import SwiftUI

struct RecordDetailView: View {
    let record: BasketballRecord
    
    var body: some View {
        List {
            Section(header: Text("基本信息")) {
                DetailRow(title: "日期", value: record.wrappedDate.formatted())
                DetailRow(title: "比赛类型", value: record.wrappedGameType)
                DetailRow(title: "时长", value: "\(record.duration)分钟")
            }
            
            Section(header: Text("感受")) {
                DetailRow(title: "运动强度", value: String(repeating: "⭐️", count: Int(record.intensity)))
                DetailRow(title: "疲惫程度", value: String(repeating: "💪", count: Int(record.fatigue)))
            }
            
            Section(header: Text("心得")) {
                Text(record.wrappedNotes)
                    .font(.body)
                    .padding(.vertical, 8)
            }
            
            Section(header: Text("标签")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(record.tagArray, id: \.wrappedId) { tag in
                            Text(tag.wrappedName)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("记录详情")
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
} 