# Worker Management App - Complete Documentation

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Technology Stack](#technology-stack)
4. [Installation & Setup](#installation--setup)
5. [Database Structure](#database-structure)
6. [User Roles](#user-roles)
7. [Key Features Explained](#key-features-explained)
8. [How to Use](#how-to-use)
9. [Project Structure](#project-structure)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

**Worker Management App** is a Flutter-based mobile and web application designed to manage workers, track attendance through GPS location, manage salaries, and handle advance payments.

### Main Purpose
- Help companies manage their workers efficiently
- Track worker attendance with GPS verification
- Handle salary and advance payments
- Generate reports and manage worker data

---

## ✨ Features

### For Admins:
1. ✅ **Dashboard** - View statistics (Total Workers, Logged In, Absent)
2. ✅ **Worker Management** - Add, Edit, Delete workers with location
3. ✅ **Login Status Tracking** - Monitor who's logged in/out
4. ✅ **Advance Approval** - Approve/Reject advance requests
5. ✅ **Salary Management** - Process monthly salaries
6. ✅ **Reports** - Generate attendance and salary reports
7. ✅ **CSV Export** - Export data to Excel/CSV

### For Workers:
1. ✅ **Login/Logout** - Clock in/out with GPS verification
2. ✅ **Request Advance** - Request advance salary with reason
3. ✅ **View My Attendance** - See login/logout history
4. ✅ **View My Salary** - Check salary records
5. ✅ **View My Advances** - Track advance requests and status

---

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter 3.x |
| **Language** | Dart |
| **Database** | SQLite (sqflite) |
| **State Management** | Provider Pattern |
| **Storage** | SharedPreferences |
| **Location** | Geolocator, Geocoding |
| **Date/Time** | Intl |
| **UI Design** | Material 3 |

---

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK (3.0 or higher)
- Chrome browser (for web testing)
- Code editor (VS Code recommended)

### Step 1: Clone/Download Project
```bash
cd C:\Users\Admin\Desktop\Project\worker_managment_app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Run on Web
```bash
flutter run -d chrome --web-port=8080
```

### Step 4: Default Login Credentials
**Admin:**
- Phone: `8104246218`
- Password: `admin123`
- Role: Select "Admin"

---

## 🗄️ Database Structure

### Tables

#### 1. **users** (Stores all users - Admin & Workers)
```
- id (Primary Key)
- name
- phone (10 digits, unique)
- password
- role (admin/worker)
- wage (daily wage)
- joinDate
- workLocationLatitude (GPS)
- workLocationLongitude (GPS)
- workLocationAddress
- locationRadius (default: 100 meters)
```

#### 2. **login_status** (Login/Logout tracking)
```
- id (Primary Key)
- workerId (Foreign Key)
- date (YYYY-MM-DD)
- loginTime (HH:mm:ss)
- logoutTime (HH:mm:ss)
- loginLatitude
- loginLongitude
- loginAddress
- logoutLatitude
- logoutLongitude
- logoutAddress
- isLoggedIn (boolean)
- loginDistance (meters from work location)
- logoutDistance (meters from work location)
```

#### 3. **advance** (Advance salary requests)
```
- id (Primary Key)
- workerId (Foreign Key)
- amount
- date
- purpose (Medical/Personal/Emergency/Family/Education/Other)
- note (detailed explanation)
- status (pending/approved/rejected/deducted)
- deductedFromSalaryId
- approvedBy (Admin ID)
- approvedDate
```

#### 4. **salary** (Monthly salary records)
```
- id (Primary Key)
- workerId (Foreign Key)
- month
- year
- totalDays
- presentDays
- absentDays
- grossSalary
- totalAdvance
- netSalary
- paidDate
```

#### 5. **attendance** (Legacy - replaced by login_status)
```
- id (Primary Key)
- workerId (Foreign Key)
- date
- status (present/absent)
```

---

## 👥 User Roles

### 1. Admin
**Can Do:**
- Manage all workers (Add/Edit/Delete)
- View all login statuses
- Approve/Reject advance requests
- Process salaries
- Generate reports
- Export data to CSV

**Cannot Do:**
- Cannot login/logout like workers
- Cannot request advances

### 2. Worker
**Can Do:**
- Login/Logout with GPS verification
- Request advances with purpose
- View own attendance history
- View own salary records
- View own advance requests

**Cannot Do:**
- Cannot access admin features
- Cannot approve own advances
- Cannot edit other workers' data

---

## 🔑 Key Features Explained

### 1. GPS-Based Attendance

**How it Works:**
1. When admin adds a worker, they capture work location (GPS coordinates)
2. Worker must be within 100 meters of work location to login
3. System records GPS coordinates at login and logout
4. Calculates distance from work location
5. Auto-calculates working hours

**Example:**
```
Work Location: 19.1234, 72.5678
Worker Location at Login: 19.1235, 72.5679
Distance: 45 meters ✅ (Within 100m radius)
Login: Allowed
```

### 2. Advance Request System

**Workflow:**
```
Worker → Request Advance → Enter Amount + Purpose + Note
         ↓
Admin → View in "Manage Advances" → Pending Tab
         ↓
Admin → Approve/Reject
         ↓
Worker → See Status in "My Advances"
         ↓
(If Approved) → Auto-deducted from next salary
```

**Advance Purposes:**
- 💊 Medical - Health/medical emergencies
- 👤 Personal - Personal needs
- ⚠️ Emergency - Urgent situations
- 👨‍👩‍👧‍👦 Family - Family requirements
- 📚 Education - Education expenses
- 🚗 Transportation - Travel needs
- 📝 Other - Other reasons

**Status Flow:**
```
Pending → Approved → Deducted
          ↓
        Rejected
```

### 3. Location Capture

**Two Methods:**

**Method 1: GPS Fetch (Automatic)**
1. Click "Fetch Current Location (GPS)"
2. Browser asks for permission
3. System gets: Latitude, Longitude, Address
4. All fields auto-filled

**Method 2: Manual Entry**
1. Enter address manually
2. Enter latitude (e.g., 28.6139)
3. Enter longitude (e.g., 77.2090)

### 4. Login Status Tracking

**Replaces Old Attendance System:**
- Old: Simple Present/Absent marking
- New: Full login/logout tracking with GPS

**What's Tracked:**
- Login time & location
- Logout time & location
- Distance from work location
- Working hours (auto-calculated)
- Address at login/logout

**Working Hours Calculation:**
```
Login Time: 09:00 AM
Logout Time: 05:30 PM
Working Hours: 8.5 hours
```

---

## 📱 How to Use

### For First Time Setup (Admin)

**Step 1: Login as Admin**
```
Phone: 8104246218
Password: admin123
Role: Admin
```

**Step 2: Add First Worker**
1. Click "Add Worker" card on dashboard
2. Fill in details:
   - Full Name: Ram Kumar
   - Phone: 9876543210
   - Designation: Labor
   - Daily Wage: 500
   - Joining Date: Select date
   - Password: ram123
3. Scroll to "Work Location" section
4. Click "Fetch Current Location (GPS)" OR enter manually
5. Click "Add Worker"

**Step 3: Worker Can Now Login**
```
Phone: 9876543210
Password: ram123
Role: Worker
```

### For Daily Worker Login

**Step 1: Worker Arrives at Work**
1. Open app
2. Login (phone + password + select "Worker")
3. See worker dashboard

**Step 2: Clock In**
1. Click "Login Now" on status banner
2. System checks GPS location
3. If within 100m → Login successful
4. If outside 100m → Shows distance error

**Step 3: During Work**
- Dashboard shows "Logged In" status
- Shows login time

**Step 4: Clock Out**
1. Click "Logout Now" on status banner
2. System checks GPS location again
3. If within 100m → Logout successful
4. Working hours calculated automatically

### For Requesting Advance (Worker)

**Step 1: Open Request Form**
1. Login as worker
2. Click "Request Advance" card (purple)

**Step 2: Fill Form**
```
Amount: 5000
Purpose: Medical (select from dropdown)
Note: "Family member needs urgent medical treatment"
```

**Step 3: Submit**
- Click "Submit Request"
- Status: Pending
- Wait for admin approval

**Step 4: Check Status**
- Go to "My Advances"
- See request with status badge:
  - 🟠 Pending
  - 🟢 Approved
  - 🔴 Rejected
  - 🔵 Deducted

### For Approving Advances (Admin)

**Step 1: View Requests**
1. Login as admin
2. Click "Manage Advances" card (purple)

**Step 2: Review Pending Tab**
- See all pending requests
- Each card shows:
  - Worker name
  - Amount
  - Purpose
  - Note/reason

**Step 3: Approve or Reject**
- Click "Approve" → Confirm → Approved!
- Click "Reject" → Confirm → Rejected!

**Step 4: Track Status**
- Approved tab: All approved advances
- Rejected tab: All rejected advances
- Deducted tab: Already deducted from salary

---

## 📂 Project Structure

```
lib/
├── models/                 # Data models
│   ├── user.dart          # User (Admin/Worker)
│   ├── advance.dart       # Advance requests
│   ├── salary.dart        # Salary records
│   ├── login_status.dart  # Login/Logout tracking
│   └── attendance.dart    # (Legacy)
│
├── providers/             # State management
│   ├── user_provider.dart
│   ├── advance_provider.dart
│   ├── salary_provider.dart
│   └── login_status_provider.dart
│
├── screens/               # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── admin_dashboard_screen.dart
│   ├── worker_dashboard_screen.dart
│   ├── add_worker_screen.dart
│   ├── login_status_screen.dart
│   ├── manage_advances_screen.dart
│   ├── request_advance_screen.dart
│   ├── my_advance_screen.dart
│   ├── my_salary_screen.dart
│   ├── my_attendance_screen.dart
│   ├── salary_advance_screen.dart
│   ├── reports_screen.dart
│   └── settings_screen.dart
│
├── services/              # Core services
│   ├── database_helper.dart      # SQLite database
│   ├── session_manager.dart      # Login sessions
│   └── location_service.dart     # GPS & location
│
├── widgets/               # Reusable UI components
│   ├── custom_app_bar.dart
│   ├── custom_text_field.dart
│   └── custom_button.dart
│
└── main.dart              # App entry point
```

---

## 🔧 Troubleshooting

### Issue 1: App won't start
**Solution:**
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-port=8080
```

### Issue 2: Port already in use
**Error:** `Port 8080 already in use`
**Solution:**
```bash
# Try different port
flutter run -d chrome --web-port=8081
```

### Issue 3: Location not working
**Cause:** Browser permission denied
**Solution:**
1. Allow location when browser asks
2. Check browser settings → Site permissions
3. Enable location for localhost

### Issue 4: Database not saving data
**Solution:**
- Check browser console for errors
- Clear browser cache
- Restart app

### Issue 5: Can't login
**Check:**
- Phone number is 10 digits
- Role is selected correctly
- Password is correct
- Default admin: 8104246218 / admin123

### Issue 6: Worker can't clock in
**Possible Reasons:**
- Not within 100m of work location
- Location permission denied
- GPS not accurate

**Solution:**
- Move closer to work location
- Enable location services
- Wait for GPS to stabilize

---

## 📊 Database Schema Version

**Current Version:** 2

**Migration from v1 to v2:**
- Added location fields to users table
- Added new fields to advance table
- Created login_status table
- Maintains backward compatibility

**Future Upgrades:**
- Version 3: Add salary deduction automation
- Version 4: Add notifications
- Version 5: Add multi-language support

---

## 🚀 Running on Different Platforms

### Web (Current)
```bash
flutter run -d chrome --web-port=8080
```

### Android
```bash
flutter run -d android
```

### Windows
```bash
flutter run -d windows
```

### Build APK (Android)
```bash
flutter build apk --release
```

### Build Web
```bash
flutter build web
```

---

## 📝 Important Notes

1. **Database Location (Web):**
   - Uses IndexedDB in browser
   - Database name: `worker_management_app.db`
   - Persists across sessions
   - Cleared when browser data is cleared

2. **GPS Accuracy:**
   - Best accuracy: Outdoor with clear sky
   - Indoor: May have 10-50m error
   - Default radius: 100 meters (configurable)

3. **Phone Number:**
   - Must be exactly 10 digits
   - No special characters
   - Example: 9876543210

4. **Passwords:**
   - Minimum 6 characters
   - Stored as plain text (consider encryption for production)

5. **Advance Status:**
   - Pending: Waiting for admin
   - Approved: Admin approved, not yet deducted
   - Rejected: Admin rejected
   - Deducted: Already taken from salary

---

## 🎯 Future Enhancements

### Planned Features:
1. ✅ Auto-deduction of advances from salary
2. ✅ Negative balance handling
3. ⏳ Push notifications for advance approval
4. ⏳ Biometric login
5. ⏳ Multi-language support
6. ⏳ Dark mode
7. ⏳ Salary slip PDF generation
8. ⏳ WhatsApp notifications
9. ⏳ Cloud backup
10. ⏳ Mobile app optimization

---

## 👨‍💻 Developer Information

**Project Type:** Flutter Web & Mobile App
**Database:** SQLite (local storage)
**Architecture:** Provider Pattern (MVVM-like)
**Platform Support:** Web, Android, iOS, Windows, macOS, Linux

---

## 📞 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review error messages in browser console (F12)
3. Check database initialization logs
4. Verify all dependencies installed: `flutter pub get`

---

## 🎉 Quick Start Checklist

- [ ] Flutter installed
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] App running on port 8080
- [ ] Logged in as admin (8104246218 / admin123)
- [ ] Added first worker
- [ ] Worker can login
- [ ] Worker location captured
- [ ] GPS verification working
- [ ] Advance request tested
- [ ] Advance approval tested

---

**Last Updated:** 2025-10-29
**Version:** 1.0.0
**Database Version:** 2
