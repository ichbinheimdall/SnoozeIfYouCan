import WidgetKit
import SwiftUI

@main
struct SnoozeWidgetBundle: WidgetBundle {
    var body: some Widget {
        SnoozeAlarmWidget()
        
        if #available(iOS 26.0, *) {
            AlarmLiveActivityWidget()
        }
    }
}
