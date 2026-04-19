import Foundation
import SwiftData

@Model
class Student {
    var id: UUID
    var name: String
    var fatherName: String
    var motherName: String
    var dob: Date?
    var photo: Data?
    var status: String

    init(name: String, fatherName: String, motherName: String, dob: Date?, photo: Data?, status: String) {
        self.id = UUID()
        self.name = name
        self.fatherName = fatherName
        self.motherName = motherName
        self.dob = dob
        self.photo = photo
        self.status = status
    }
}
