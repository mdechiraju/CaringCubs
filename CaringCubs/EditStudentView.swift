import SwiftUI
import SwiftData
import PhotosUI

struct EditStudentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    var student: Student

    @State private var name: String
    @State private var fatherName: String
    @State private var motherName: String
    @State private var status: String

    @State private var pickedImage: UIImage?
    @State private var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showValidation = false

    init(student: Student) {
        self.student  = student
        _name         = State(initialValue: student.name)
        _fatherName   = State(initialValue: student.fatherName)
        _motherName   = State(initialValue: student.motherName)
        _status       = State(initialValue: student.status)
        _photoData    = State(initialValue: student.photo)
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !fatherName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !motherName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        if let image = pickedImage {
            ImageCropperView(
                image: image,
                onCropped: { croppedImage in
                    photoData = croppedImage.jpegData(compressionQuality: 0.8)
                    pickedImage = nil
                },
                onCancel: {
                    pickedImage = nil
                }
            )
        } else {
            formView
        }
    }

    var formView: some View {
        NavigationStack {
            Form {

                // ── Photo ────────────────────────────────────────
                Section {
                    HStack {
                        Spacer()
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let data = photoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.85, green: 0.88, blue: 1.0))
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2)
                            )

                            // Camera badge
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.4, blue: 0.6))
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 4, y: 4)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // ── Student Name ─────────────────────────────────
                Section(header: Text("Student")) {
                    TextField("Name", text: $name)
                    if showValidation && name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // ── Parent Names ─────────────────────────────────
                Section(header: Text("Parents")) {
                    TextField("Father Name", text: $fatherName)
                    if showValidation && fatherName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Father name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    TextField("Mother Name", text: $motherName)
                    if showValidation && motherName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Mother name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // ── Status ───────────────────────────────────────
                Section(header: Text("Status")) {
                    Picker("Status", selection: $status) {
                        Text("Active").tag("Active")
                        Text("Dropped").tag("Dropped")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Student")
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
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        pickedImage = image
                        selectedItem = nil
                    }
                }
            }
        }
    }

    func save() {
        showValidation = true
        guard isFormValid else { return }

        student.name       = name.trimmingCharacters(in: .whitespaces)
        student.fatherName = fatherName.trimmingCharacters(in: .whitespaces)
        student.motherName = motherName.trimmingCharacters(in: .whitespaces)
        student.status     = status
        student.photo      = photoData

        try? context.save()
        dismiss()
    }
}
