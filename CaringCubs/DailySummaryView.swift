import SwiftUI
import SwiftData

struct DailySummaryView: View {
    @Query var attendanceList: [Attendance]

    var todayRecords: [Attendance] {
        attendanceList.filter {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }
    }

    var body: some View {
        NavigationStack {
            List(todayRecords) { record in
                VStack(alignment: .leading) {
                    Text(record.student.name).bold()

                    Text("In: \(format(record.checkInTime))")
                    Text("Out: \(format(record.checkOutTime))")
                }
                .padding(6)
            }
            .navigationTitle("Today Summary")
        }
    }

    func format(_ date: Date?) -> String {
        guard let date else { return "-" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
