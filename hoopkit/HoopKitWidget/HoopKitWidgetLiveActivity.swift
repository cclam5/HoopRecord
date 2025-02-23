//
//  HoopKitWidgetLiveActivity.swift
//  HoopKitWidget
//
//  Created by CC . on 2025/2/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HoopKitWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HoopKitWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HoopKitWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HoopKitWidgetAttributes {
    fileprivate static var preview: HoopKitWidgetAttributes {
        HoopKitWidgetAttributes(name: "World")
    }
}

extension HoopKitWidgetAttributes.ContentState {
    fileprivate static var smiley: HoopKitWidgetAttributes.ContentState {
        HoopKitWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HoopKitWidgetAttributes.ContentState {
         HoopKitWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HoopKitWidgetAttributes.preview) {
   HoopKitWidgetLiveActivity()
} contentStates: {
    HoopKitWidgetAttributes.ContentState.smiley
    HoopKitWidgetAttributes.ContentState.starEyes
}
