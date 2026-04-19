import SwiftUI
import SwiftData

@main
struct StudentTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Student.self, Attendance.self])
    }
}
