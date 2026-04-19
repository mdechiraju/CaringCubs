# 🐾 CaringCubs — Daycare Attendance Tracker

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue?style=for-the-badge&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift" />
  <img src="https://img.shields.io/badge/SwiftUI-Framework-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/SwiftData-Persistence-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-In%20Development-yellow?style=for-the-badge" />
</p>

> A modern iOS app for daycare centers to manage student attendance, track check-in and check-out times, and maintain detailed logs — all in one place.

---

## 📱 Screenshots

> _Screenshots coming soon_

---

## ✨ Features

### 👶 Student Management
- Add students with name, father's name, mother's name, profile photo, and status
- Upload and **crop profile photos** with an interactive circle cropper (pinch to zoom, drag to reposition)
- Edit student details including names, photo, and status at any time
- Mark students as **Active** or **Inactive**
- Delete students with a long press context menu
- Search students by name or parent name in real time

### ✅ Check-In / Check-Out
- Check students in and out by selecting the dropping/picking parent
- View current check-in status on the student list with a **green dot badge**
- Prevent duplicate check-ins — the Check In button is disabled if already checked in
- Replace or update student profile photo directly from the Check In/Out screen
- Camera badge overlay on profile photo indicates it is tappable to update

### 📋 Attendance Logs
- View all attendance records grouped by date with record count per day  
  e.g. `April 9, 2026 (7)`
- Color-coded entries:
  - 🟢 **Green** — Check-in time and dropped by
  - 🔵 **Blue** — Check-out time and picked by
  - 🟠 **Orange** — Not checked out yet
- **Red clock icon** alert on entries where total checked-in time exceeds **8 hours**
- Duration displayed on each record (e.g. `6h 30m`)
- Tap any record to **edit** check-in/out times and parent names with no date restrictions
- **Swipe left to delete** duplicate entries (only available when multiple records exist for the same day)
- **Export to CSV** — share attendance logs via email, AirDrop, or Files app

### 📅 Today Summary
- Dedicated tab showing only today's attendance records at a glance
- See check-in and check-out times for all students present today

### 🖼 Photo Cropper
- Interactive circle crop tool for all profile photos
- Pinch to zoom in/out
- Drag to reposition the image within the crop circle
- Automatic **EXIF orientation fix** — photos always appear correctly regardless of how they were taken
- Works consistently on both Add Student and Check In/Out screens

### 📤 CSV Export
- Export complete attendance log as a CSV file
- Columns: Date, Student, Check In Time, Dropped By, Check Out Time, Picked By, Duration
- File named with today's date e.g. `AttendanceLogs_2026-04-18.csv`
- Compatible with Numbers, Microsoft Excel, and Google Sheets

---

## 🏗 Architecture

### Tech Stack
| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Photo Picker | PhotosUI |
| Image Cropping | Custom UIViewRepresentable |
| Minimum iOS | iOS 17.0 |

### Project Structure

```
CaringCubs/
├── Models/
│   ├── Student.swift           # Student data model
│   ├── Attendance.swift        # Attendance record model
│   └── Item.swift              # Default SwiftData boilerplate
│
├── Views/
│   ├── ContentView.swift       # Root TabView
│   ├── StudentListView.swift   # Student grid with search & filter
│   ├── AddStudentView.swift    # Add new student form
│   ├── EditStudentView.swift   # Edit existing student details
│   ├── CheckInOutView.swift    # Check-in / check-out screen
│   ├── AttendanceView.swift    # All attendance logs
│   ├── EditAttendanceView.swift# Edit attendance record
│   ├── DailySummaryView.swift  # Today's summary
│   └── ImageCropperView.swift  # Interactive photo cropper
│
└── App/
    └── StudentTrackerApp.swift # App entry point & SwiftData container
```

### Data Models

#### `Student`
| Field | Type | Description |
|---|---|---|
| id | UUID | Unique identifier |
| name | String | Student full name |
| fatherName | String | Father's name |
| motherName | String | Mother's name |
| dob | Date? | Date of birth (optional) |
| photo | Data? | Profile photo as JPEG data |
| status | String | "Active" or "Dropped" |

#### `Attendance`
| Field | Type | Description |
|---|---|---|
| id | UUID | Unique identifier |
| student | Student | Relationship to student |
| date | Date | Date of attendance record |
| checkInTime | Date? | Time student was checked in |
| checkOutTime | Date? | Time student was checked out |
| droppedBy | String | Parent who dropped the student |
| pickedBy | String | Parent who picked the student |

---

## 🖥 Screens

### Students Tab
- Beautiful dark-themed 2-column card grid
- Each card shows: circular profile photo, student name, father and mother names, Active/Inactive status pill, and a green check-in dot when currently checked in
- **Active/Inactive filter pills** to toggle visibility of inactive students
- Real-time search bar with keyboard dismiss on scroll
- Header shows live count of how many students are checked in today
- Long press any card to: Edit Student, Mark as Active/Inactive, or Delete

### Check In / Out Screen
- Tap any student card to navigate to their check-in screen
- Shows student photo, name, and parent names
- Dropdown to select which parent is dropping/picking up
- Check In and Check Out buttons with smart enable/disable logic
- Tap the profile photo to replace it with a new cropped photo

### All Logs Screen
- Full attendance history sorted by most recent date first
- Section headers show date and total record count
- Tap any row to edit the record
- Swipe left to delete duplicate records
- Export button in toolbar generates and shares a CSV file

### Today Screen
- Filtered view showing only today's attendance records
- Quick glance at who is in and who has been picked up

---

## 🚀 Getting Started

### Requirements
- Xcode 15 or later
- iOS 17.0 or later
- macOS Ventura or later (for development)

### Installation
1. Clone the repository:
   ```bash
   git clone git@github.com:mdechiraju/CaringCubs.git
   ```
2. Open `CaringCubs.xcodeproj` in Xcode
3. Select your target device or simulator
4. Press **Cmd + R** to build and run

### First Launch
- No setup required — SwiftData creates the local database automatically on first launch
- Tap the **+** button to add your first student
- All data is stored locally on the device

---

## 🔒 Privacy & Security

- All student and attendance data is stored **locally on the device** using SwiftData
- No data is sent to any server or third party
- Profile photos are stored as compressed JPEG data within the local database
- The app requires **Photo Library access** only when uploading a student photo
- Designed for use by daycare staff — not intended for use by children directly

---

## 🗺 Roadmap

- [ ] Local notifications at 5:50 PM to remind staff to check out remaining students
- [ ] Auto check-out at 6:00 PM for students still checked in
- [ ] Monthly attendance report per student
- [ ] Parent contact information (phone number)
- [ ] Date of birth and age display
- [ ] Dark mode support across all screens
- [ ] iPad optimized layout
- [ ] App Store release

---

## 👨‍💻 Author

**Murali** — [@mdechiraju](https://github.com/mdechiraju)

---

## 📄 License

This project is private and not licensed for public use or distribution.

---

<p align="center">Made with ❤️ for daycare heroes everywhere 🐾</p>
