import SwiftUI
import SwiftData
import PhotosUI

struct CheckInOutView: View {
    var student: Student
    @Query var attendanceList: [Attendance]
    @Environment(\.modelContext) private var context

    @State private var selectedParent: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Image handling
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?       // raw image — triggers cropper swap

    var latestRecord: Attendance? {
        attendanceList
            .filter { $0.student.id == student.id }
            .sorted { ($0.checkInTime ?? Date.distantPast) > ($1.checkInTime ?? Date.distantPast) }
            .first
    }

    var isCheckedIn: Bool {
        latestRecord?.checkInTime != nil && latestRecord?.checkOutTime == nil
    }

    var parentOptions: [String] {
        [student.fatherName, student.motherName].filter { !$0.isEmpty }
    }

    var body: some View {
        // ✅ Inline view swap — no sheets, no conflicts
        if let image = pickedImage {
            ImageCropperView(
                image: image,
                onCropped: { croppedImage in
                    student.photo = croppedImage.jpegData(compressionQuality: 0.8)
                    try? context.save()
                    pickedImage = nil           // swap back to main view
                },
                onCancel: {
                    pickedImage = nil           // swap back without saving
                }
            )
        } else {
            mainView
        }
    }

    var mainView: some View {
        ScrollView {
            VStack(spacing: 24) {

                HStack(spacing: 12) {
                    studentImageView

                    VStack(alignment: .leading, spacing: 6) {
                        Text(student.name).font(.title2).bold()
                        Text("Father: \(student.fatherName)")
                        Text("Mother: \(student.motherName)")

                        if let checkIn = latestRecord?.checkInTime, isCheckedIn {
                            Text("Already checked in at \(formatTime(checkIn))")
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                VStack(alignment: .leading) {
                    Text("Choose a Parent").foregroundColor(.secondary)

                    Picker("Parent", selection: $selectedParent) {
                        Text("Choose a Parent").tag("")
                        ForEach(parentOptions, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)

                HStack {
                    Button("Check In", action: checkIn)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCheckedIn ? .gray : .blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isCheckedIn)

                    Button("Check Out", action: checkOut)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!isCheckedIn ? .gray : .green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(!isCheckedIn)
                }
            }
            .padding()
        }
        .navigationTitle("Check In / Out")
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image         // ← triggers swap to cropper
                    selectedItem = nil
                }
            }
        }
        .alert("Info", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    var studentImageView: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Group {
                if let data = student.photo,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                // 📷 small camera badge so user knows it's tappable
                Image(systemName: "camera.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .font(.system(size: 20))
                    .offset(x: 28, y: 28)
            )
        }
        .buttonStyle(.plain)
    }

    func checkIn() {
        guard !selectedParent.isEmpty else {
            alertMessage = "Please choose a parent!"
            showAlert = true
            return
        }
        let newRecord = Attendance(student: student, droppedBy: selectedParent)
        newRecord.checkInTime = Date()
        context.insert(newRecord)
        try? context.save()
        alertMessage = "Checked in successfully!"
        showAlert = true
        selectedParent = ""
    }

    func checkOut() {
        guard let record = latestRecord else { return }
        guard !selectedParent.isEmpty else {
            alertMessage = "Please choose a parent!"
            showAlert = true
            return
        }
        record.checkOutTime = Date()
        record.pickedBy = selectedParent
        try? context.save()
        alertMessage = "Checked out successfully!"
        showAlert = true
        selectedParent = ""
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
