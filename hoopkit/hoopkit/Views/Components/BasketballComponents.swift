import SwiftUI
import CoreData

// 导入触感管理器
@_implementationOnly import UIKit

// 类型选择组件
struct GameTypeSelector: View {
    let gameTypes: [String]
    @Binding var selectedType: String
    
    var body: some View {
        HStack {
            Text("类型")
                .font(ViewStyles.labelFont)
                .foregroundColor(.customSecondaryText)
            
            Menu {
                ForEach(gameTypes, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        HStack {
                            Text(type)
                                .foregroundColor(.customPrimaryText)
                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.customBrandPrimary)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedType)
                        .font(ViewStyles.labelFont)
                        .foregroundColor(.customPrimaryText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryText)
                }
                .padding(.horizontal, ViewStyles.defaultPadding)
                .padding(.vertical, ViewStyles.smallPadding)
                .background(Color.customListBackground)
                .cornerRadius(ViewStyles.cornerRadius)
            }
        }
    }
}

// 强度控制组件
struct IntensityControl: View {
    @Binding var intensity: Int
    var isEditing: Bool = true  // 添加编辑状态参数，默认为可编辑
    
    var body: some View {
        HStack {
            Text("强度")
                .font(ViewStyles.labelFont)
                .foregroundColor(.customSecondaryText)
            
            HStack(spacing: ViewStyles.tinyPadding) {
                ForEach(1...5, id: \.self) { index in
                    if isEditing {
                        Button(action: { intensity = index }) {
                            Image(systemName: index <= intensity ? "flame.fill" : "flame")
                                .font(ViewStyles.labelFont)
                                .foregroundColor(index <= intensity ? .customBrandPrimary : .customSecondaryText)
                        }
                    } else {
                        Image(systemName: index <= intensity ? "flame.fill" : "flame")
                            .font(ViewStyles.labelFont)
                            .foregroundColor(index <= intensity ? .customBrandPrimary : .customSecondaryText)
                    }
                }
            }
            .padding(.horizontal, ViewStyles.defaultPadding)
            .padding(.vertical, ViewStyles.smallPadding)
            .background(isEditing ? Color.customListBackground : Color.clear)
            .cornerRadius(ViewStyles.cornerRadius)
        }
    }
}

// 时长选择组件
struct DurationSelector: View {
    @Binding var duration: Double
    let presets: [Int]
    var isEditing: Bool = true  // 添加编辑状态参数，默认为可编辑
    
    var body: some View {
        VStack(alignment: .leading, spacing: ViewStyles.smallPadding) {
            HStack {
                Text("时长")
                    .font(ViewStyles.labelFont)
                    .foregroundColor(.customSecondaryText)
                Spacer()
                Text("\(Int(duration))分钟")
                    .font(ViewStyles.labelFont)
                    .foregroundColor(.customPrimaryText)
            }
            
            if isEditing {
                Slider(value: $duration, in: 0...240, step: 1)
                    .accentColor(.customBrandPrimary)
                    .onChange(of: duration) { _ in
                        HapticManager.light()
                    }
                
                HStack(spacing: ViewStyles.smallPadding) {
                    ForEach(presets, id: \.self) { mins in
                        Button(action: { 
                            duration = Double(mins)
                            HapticManager.light()
                        }) {
                            Text("\(mins)")
                                .font(ViewStyles.smallFont)
                                .padding(.horizontal, ViewStyles.defaultPadding)
                                .padding(.vertical, ViewStyles.smallPadding)
                                .background(duration == Double(mins) ? 
                                    Color.customBrandPrimary : 
                                    Color.customListBackground)
                                .foregroundColor(duration == Double(mins) ? .white : .customPrimaryText)
                                .cornerRadius(ViewStyles.cornerRadius)
                        }
                    }
                }
            }
        }
    }
}

// 心得输入组件
struct NotesEditor: View {
    @Binding var notes: String
    
    var body: some View {
        ScrollView {
            TextEditor(text: $notes)
                .font(ViewStyles.labelFont)
                .frame(minHeight: 400)
                .overlay(  
                    Group {
                        if notes.isEmpty {
                            Text("记录今天的心得...")
                                .font(ViewStyles.labelFont)
                                .foregroundColor(ViewStyles.labelColor)
                                .padding(.leading, 5)       // 调整左边距以匹配光标位置
                                .padding(.top, 8)          // 调整顶部边距以匹配光标位置
                        }
                    },
                    alignment: .topLeading
                )
        }
        .frame(maxHeight: 600)
    }
}

// 标签输入组件
struct TagInput: View {
    @Binding var newTagName: String
    @Binding var selectedTags: Set<BasketballTag>
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ViewStyles.defaultPadding) {
            TextField("输入标签名称，空格键添加", text: $newTagName)
                .font(ViewStyles.labelFont)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit(onSubmit)
                .onChange(of: newTagName) { newValue in
                    if newValue.last == " " {  // 检测到空格
                        newTagName = newValue.trimmingCharacters(in: .whitespaces)
                        onSubmit()
                    }
                }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ViewStyles.smallPadding) {
                    ForEach(Array(selectedTags)) { tag in
                        TagView(tag: tag, onRemove: {
                            selectedTags.remove(tag)
                        })
                    }
                }
            }
        }
    }
}

// 标签视图组件
struct TagView: View {
    let tag: BasketballTag
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(tag.wrappedName)
                .font(ViewStyles.labelFont)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, ViewStyles.defaultPadding)
        .padding(.vertical, ViewStyles.smallPadding)
        .background(ViewStyles.backgroundColor)
        .cornerRadius(ViewStyles.cornerRadius)
    }
} 
