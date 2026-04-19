import Foundation
import SwiftData

@Model
class Attendance {
    var id: UUID
    var student: Student
    var checkInTime: Date?
    var checkOutTime: Date?
    var droppedBy: String
    var pickedBy: String
    var date: Date

    init(student: Student, droppedBy: String) {
        self.id = UUID()
        self.student = student
        self.droppedBy = droppedBy
        self.date = Date()
        self.checkInTime = Date()
        self.pickedBy = ""
    }
}
