import SwiftUI
import SwiftData

struct StudentListView: View {
    @Query var students: [Student]
    @Query var attendanceList: [Attendance]
    @Environment(\.modelContext) private var context
    @State private var showAddStudent = false
    @State private var searchText = ""
    @State private var showInactive = false
    @State private var studentToEdit: Student?

    var activeStudents: [Student] {
        students.filter { $0.status == "Active" }
    }

    var filteredStudents: [Student] {
        let base = showInactive ? students : activeStudents
        if searchText.isEmpty { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.fatherName.localizedCaseInsensitiveContains(searchText) ||
            $0.motherName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var checkedInCount: Int {
        activeStudents.filter { isCheckedIn(student: $0) }.count
    }

    func isCheckedIn(student: Student) -> Bool {
        guard let latest = attendanceList
            .filter({ $0.student.id == student.id })
            .sorted(by: { ($0.checkInTime ?? .distantPast) > ($1.checkInTime ?? .distantPast) })
            .first else { return false }
        return latest.checkInTime != nil && latest.checkOutTime == nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Dark background ──────────────────────────────
                Color(red: 0.11, green: 0.11, blue: 0.14)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Header ───────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CaringCubs")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.4, blue: 0.6),
                                                 Color(red: 0.4, green: 0.6, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("\(checkedInCount) of \(activeStudents.count) checked in today")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                        }

                        Spacer()

                        Button {
                            showAddStudent = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.4, blue: 0.6),
                                                     Color(red: 0.9, green: 0.3, blue: 0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(
                                        color: Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.4),
                                        radius: 8, x: 0, y: 4
                                    )
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                    // ── Search bar ───────────────────────────────
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.white.opacity(0.4))
                            .font(.system(size: 15))

                        TextField("", text: $searchText,
                                  prompt: Text("Search by name or parent...")
                                      .foregroundColor(Color.white.opacity(0.35))
                        )
                        .foregroundColor(.white)
                        .tint(.pink)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil
                                )
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // ── Active / Inactive filter pills ───────────
                    HStack(spacing: 8) {
                        FilterPill(
                            label: "Active (\(activeStudents.count))",
                            isSelected: !showInactive,
                            color: .green
                        ) {
                            showInactive = false
                        }

                        FilterPill(
                            label: "Inactive (\(students.count - activeStudents.count))",
                            isSelected: showInactive,
                            color: .orange
                        ) {
                            showInactive = true
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // ── Student Grid ─────────────────────────────
                    ScrollView {
                        if filteredStudents.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: showInactive ? "person.slash" : "person.3")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color.white.opacity(0.2))
                                Text(showInactive ? "No inactive students" : "No active students")
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 14),
                                          GridItem(.flexible(), spacing: 14)],
                                spacing: 14
                            ) {
                                ForEach(filteredStudents) { student in
                                    NavigationLink(destination: CheckInOutView(student: student)) {
                                        StudentCard(
                                            student: student,
                                            isCheckedIn: isCheckedIn(student: student)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            studentToEdit = student
                                        } label: {
                                            Label("Edit Student", systemImage: "pencil")
                                        }

                                        Divider()

                                        Button {
                                            student.status = student.status == "Active" ? "Dropped" : "Active"
                                            try? context.save()
                                        } label: {
                                            Label(
                                                student.status == "Active" ? "Mark as Inactive" : "Mark as Active",
                                                systemImage: student.status == "Active" ? "person.slash" : "person.fill.checkmark"
                                            )
                                        }

                                        Divider()

                                        Button(role: .destructive) {
                                            if let idx = students.firstIndex(where: { $0.id == student.id }) {
                                                context.delete(students[idx])
                                                try? context.save()
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddStudent) {
                AddStudentView()
            }
            .sheet(item: $studentToEdit) { student in
                EditStudentView(student: student)
            }
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    var label: String
    var isSelected: Bool
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Student Card
struct StudentCard: View {
    var student: Student
    var isCheckedIn: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {

                // Round photo
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let data = student.photo, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.88, blue: 1.0),
                                             Color(red: 0.88, green: 0.93, blue: 1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 3)
                    )
                    .grayscale(student.status == "Active" ? 0 : 1)

                    if isCheckedIn {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                }

                // Name & parents
                VStack(spacing: 5) {
                    Text(student.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(student.status == "Active"
                                         ? .white
                                         : Color.white.opacity(0.4))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 4) {
                        Text("👨")
                        Text(student.fatherName.isEmpty ? "—" : student.fatherName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Text("👩")
                        Text(student.motherName.isEmpty ? "—" : student.motherName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Status pill
                Text(student.status)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(student.status == "Active" ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(student.status == "Active"
                                  ? Color.green.opacity(0.15)
                                  : Color.orange.opacity(0.15))
                    )
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.07))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .opacity(student.status == "Active" ? 1.0 : 0.5)
    }
}
