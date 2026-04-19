import SwiftUI
import SwiftData
import PhotosUI

struct AddStudentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var fatherName = ""
    @State private var motherName = ""
    @State private var status = "Active"

    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var photoData: Data?

    @State private var showValidation = false      // ← only show errors after Save tapped

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !fatherName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !motherName.trimmingCharacters(in: .whitespaces).isEmpty &&
        photoData != nil
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
                // Name
                Section {
                    TextField("Name", text: $name)
                    if showValidation && name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Father Name
                Section {
                    TextField("Father Name", text: $fatherName)
                    if showValidation && fatherName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Father name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Mother Name
                Section {
                    TextField("Mother Name", text: $motherName)
                    if showValidation && motherName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Mother name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Photo
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Text(photoData == nil ? "Upload Photo" : "Change Photo")
                            Spacer()
                            if photoData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    if showValidation && photoData == nil {
                        Text("Photo is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(Circle())
                            .frame(maxWidth: .infinity)
                    }
                }

                // Status
                Section {
                    Picker("Status", selection: $status) {
                        Text("Active").tag("Active")
                        Text("Dropped").tag("Dropped")
                    }
                }
            }
            .navigationTitle("Add Student")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showValidation = true       // ← reveal any errors
                        guard isFormValid else { return }
                        let student = Student(
                            name: name.trimmingCharacters(in: .whitespaces),
                            fatherName: fatherName.trimmingCharacters(in: .whitespaces),
                            motherName: motherName.trimmingCharacters(in: .whitespaces),
                            dob: nil,
                            photo: photoData,
                            status: status
                        )
                        context.insert(student)
                        dismiss()
                    }
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
}
