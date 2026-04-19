import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StudentListView()
                .tabItem { Label("Students", systemImage: "person.3") }

            AttendanceView()
                .tabItem { Label("All Logs", systemImage: "clock") }

            DailySummaryView()
                .tabItem { Label("Today", systemImage: "calendar") }
        }
    }
}
