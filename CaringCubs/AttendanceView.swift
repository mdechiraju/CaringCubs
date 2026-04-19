import SwiftUI
import SwiftData

struct AttendanceView: View {
    @Query(sort: \Attendance.date, order: .reverse) var attendanceList: [Attendance]
    @State private var recordToEdit: Attendance?
    @Environment(\.modelContext) private var context

    var groupedByDate: [(key: Date, value: [Attendance])] {
        Dictionary(grouping: attendanceList) { Calendar.current.startOfDay(for: $0.date) }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByDate, id: \.key) { date, records in
                    Section(header: sectionHeader(date: date, count: records.count)) {
                        ForEach(records) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(record.student.name).bold()
                                    Spacer()

                                    // ✅ Red clock icon if checked in > 8 hours
                                    if isOverEightHours(record) {
                                        Image(systemName: "clock.badge.exclamationmark.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16))
                                    }

                                    Image(systemName: "pencil")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                if let checkIn = record.checkInTime {
                                    Label("In: \(format(checkIn)) by \(record.droppedBy)",
                                          systemImage: "arrow.down.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }

                                if let checkOut = record.checkOutTime {
                                    Label("Out: \(format(checkOut)) by \(record.pickedBy)",
                                          systemImage: "arrow.up.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)

                                    // Duration label
                                    if let duration = duration(record) {
                                        Label(duration, systemImage: "timer")
                                            .font(.caption)
                                            .foregroundColor(isOverEightHours(record) ? .red : .secondary)
                                    }
                                } else {
                                    Label("Not checked out yet",
                                          systemImage: "clock.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                recordToEdit = record
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if records.count > 1 {
                                    Button(role: .destructive) {
                                        deleteRecord(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Attendance Logs")
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportCSV()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(item: $recordToEdit) { record in
                EditAttendanceView(record: record)
            }
        }
    }

    // MARK: - Section Header with count
    func sectionHeader(date: Date, count: Int) -> some View {
        HStack {
            Text(date, format: Date.FormatStyle()
                .month(.wide)
                .day(.defaultDigits)
                .year(.defaultDigits)
            )
            Text("(\(count))")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.secondary)
        .textCase(nil)
    }

    // MARK: - Over 8 hours check
    func isOverEightHours(_ record: Attendance) -> Bool {
        guard let checkIn  = record.checkInTime,
              let checkOut = record.checkOutTime else { return false }
        let hours = checkOut.timeIntervalSince(checkIn) / 3600
        return hours > 8
    }

    // MARK: - Duration string
    func duration(_ record: Attendance) -> String? {
        guard let checkIn  = record.checkInTime,
              let checkOut = record.checkOutTime else { return nil }
        let totalMinutes = Int(checkOut.timeIntervalSince(checkIn) / 60)
        let hours   = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Delete
    func deleteRecord(_ record: Attendance) {
        context.delete(record)
        try? context.save()
    }

    // MARK: - Export via UIWindow (no freeze)
    func exportCSV() {
        guard let url = generateCSV() else { return }

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {

                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }

                activityVC.popoverPresentationController?.sourceView = topVC.view
                activityVC.popoverPresentationController?.sourceRect = CGRect(
                    x: topVC.view.bounds.midX, y: 100, width: 0, height: 0
                )
                activityVC.popoverPresentationController?.permittedArrowDirections = .up
                topVC.present(activityVC, animated: true)
            }
        }
    }

    // MARK: - Generate CSV
    func generateCSV() -> URL? {
        var rows: [String] = ["Date,Student,Check In Time,Dropped By,Check Out Time,Picked By,Duration"]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for (_, records) in groupedByDate {
            for record in records {
                let date      = dateFormatter.string(from: record.date)
                let name      = record.student.name
                let checkIn   = record.checkInTime  != nil ? format(record.checkInTime!)  : ""
                let checkOut  = record.checkOutTime != nil ? format(record.checkOutTime!) : ""
                let droppedBy = record.droppedBy
                let pickedBy  = record.pickedBy
                let dur       = duration(record) ?? ""
                rows.append("\"\(date)\",\"\(name)\",\"\(checkIn)\",\"\(droppedBy)\",\"\(checkOut)\",\"\(pickedBy)\",\"\(dur)\"")
            }
        }

        let csv = rows.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AttendanceLogs_\(formattedToday()).csv")

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSV write error: \(error)")
            return nil
        }
    }

    // MARK: - Helpers
    func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formattedToday() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
