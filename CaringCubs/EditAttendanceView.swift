import SwiftUI
import SwiftData

struct EditAttendanceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    var record: Attendance

    @State private var checkInTime: Date
    @State private var checkOutTime: Date
    @State private var hasCheckOut: Bool
    @State private var droppedBy: String
    @State private var pickedBy: String
    @State private var showValidationError = false

    init(record: Attendance) {
        self.record   = record
        _checkInTime  = State(initialValue: record.checkInTime ?? Date())
        _checkOutTime = State(initialValue: record.checkOutTime ?? Date())
        _hasCheckOut  = State(initialValue: record.checkOutTime != nil)
        _droppedBy    = State(initialValue: record.droppedBy)
        _pickedBy     = State(initialValue: record.pickedBy)
    }

    var body: some View {
        NavigationStack {
            Form {

                // ── Student Info ───────────────────────────────
                Section {
                    HStack(spacing: 12) {
                        Group {
                            if let data = record.student.photo,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.student.name)
                                .font(.headline)
                            Text(record.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // ── Check-in ───────────────────────────────────
                Section(header: Text("Check-in")) {
                    DatePicker(
                        "Time",
                        selection: $checkInTime,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField("Dropped by", text: $droppedBy)

                    if showValidationError &&
                       droppedBy.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Dropped by is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // ── Check-out ──────────────────────────────────
                Section(header: Text("Check-out")) {
                    Toggle("Has checked out", isOn: $hasCheckOut)

                    if hasCheckOut {
                        DatePicker(
                            "Time",
                            selection: $checkOutTime,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        TextField("Picked by", text: $pickedBy)

                        if showValidationError &&
                           pickedBy.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Picked by is required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                // ── Time conflict warning ──────────────────────
                if hasCheckOut && checkOutTime < checkInTime {
                    Section {
                        Label(
                            "Check-out time must be after check-in time",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(.orange)
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Save
    func save() {
        showValidationError = true

        guard !droppedBy.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if hasCheckOut {
            guard !pickedBy.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            guard checkOutTime >= checkInTime else { return }
        }

        record.checkInTime  = checkInTime
        record.droppedBy    = droppedBy.trimmingCharacters(in: .whitespaces)
        record.checkOutTime = hasCheckOut ? checkOutTime : nil
        record.pickedBy     = hasCheckOut ? pickedBy.trimmingCharacters(in: .whitespaces) : ""

        try? context.save()
        dismiss()
    }
}
