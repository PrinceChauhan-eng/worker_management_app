# Worker Management App - New Features TODO List

## Overview
This document outlines all the new features and improvements requested for the Worker Management App.

---

## 📋 TASK LIST

### ✅ **PHASE 1: Database Schema Updates**

#### Task 1.1: Add Location Fields to User Model
- [ ] Add `latitude` field to User model
- [ ] Add `longitude` field to User model
- [ ] Add `address` field to User model
- [ ] Update database schema in `database_helper.dart`
- [ ] Add migration logic for existing database
- [ ] Update User model `toMap()` and `fromMap()` methods

#### Task 1.2: Create Login Status Model
- [ ] Create new `LoginStatus` model class
- [ ] Fields: `id`, `userId`, `loginTime`, `logoutTime`, `loginDate`, `latitude`, `longitude`, `address`, `status`
- [ ] Add `toMap()` and `fromMap()` methods
- [ ] Create database table for login_status

---

### ✅ **PHASE 2: Location Services Setup**

#### Task 2.1: Add Required Dependencies
- [ ] Add `geolocator: ^10.1.0` to pubspec.yaml
- [ ] Add `geocoding: ^2.1.1` to pubspec.yaml
- [ ] Add `permission_handler: ^11.1.0` to pubspec.yaml
- [ ] Run `flutter pub get`

#### Task 2.2: Create Location Service
- [ ] Create `lib/services/location_service.dart`
- [ ] Implement `getCurrentLocation()` method
- [ ] Implement `getAddressFromCoordinates()` method
- [ ] Implement `requestLocationPermission()` method
- [ ] Implement `checkLocationPermission()` method
- [ ] Implement `calculateDistance()` method (to verify worker is at correct location)
- [ ] Add error handling for location services

#### Task 2.3: Configure Platform Permissions
- [ ] Update `android/app/src/main/AndroidManifest.xml` for location permissions
- [ ] Update `ios/Runner/Info.plist` for location permissions
- [ ] Add location permission descriptions

---

### ✅ **PHASE 3: UI Updates - Admin Dashboard**

#### Task 3.1: Add Status Cards to Admin Home Screen
- [ ] Create status widget showing:
  - Total Employees count
  - Logged In Employees count (today)
  - Absent Employees count (today)
- [ ] Add real-time update functionality
- [ ] Style with Material 3 design
- [ ] Add icons and color coding

#### Task 3.2: Add Worker List to Admin Home Screen
- [ ] Create `WorkerListWidget` component
- [ ] Display all workers with:
  - Name
  - Phone
  - Current status (Logged In/Logged Out/Absent)
  - Location (if logged in)
- [ ] Add search functionality
- [ ] Add filter options (All/Active/Absent)
- [ ] Make list scrollable

#### Task 3.3: Replace Attendance Screen with Login Status Screen
- [ ] Create new `LoginStatusScreen` for admin
- [ ] Show login/logout history with:
  - Worker name
  - Login date
  - Login time
  - Logout time
  - Duration
  - Location (address)
- [ ] Add date filter
- [ ] Add worker filter
- [ ] Add export to CSV functionality
- [ ] Remove old attendance marking functionality for admin

---

### ✅ **PHASE 4: Worker Registration with Location**

#### Task 4.1: Update Signup Screen
- [ ] Add location fields to signup form:
  - Address field (text input)
  - Latitude field (auto-filled)
  - Longitude field (auto-filled)
- [ ] Add "Get Current Location" button
- [ ] Show map preview (optional - using Google Maps or OpenStreetMap)
- [ ] Validate location data before registration
- [ ] Update registration logic to save location

#### Task 4.2: Update Add Worker Screen (Admin)
- [ ] Add same location fields as signup
- [ ] Add "Get Current Location" button
- [ ] Validate and save location data
- [ ] Show location on worker details

---

### ✅ **PHASE 5: Worker Login with Location Verification**

#### Task 5.1: Update Worker Login Process
- [ ] Request location permission on worker login
- [ ] Get current location when worker logs in
- [ ] Validate worker is within allowed radius of registered location
- [ ] Show error if location doesn't match
- [ ] Allow configurable radius (e.g., 100 meters, 500 meters)
- [ ] Create attendance record with location data
- [ ] Show success message with location confirmation

#### Task 5.2: Create Mark Attendance Screen
- [ ] Create new screen for manual attendance marking
- [ ] Show current location
- [ ] Show registered location
- [ ] Show distance between locations
- [ ] Add "Mark Attendance" button (only enabled if within radius)
- [ ] Save login status with timestamp and location
- [ ] Update worker status to "Logged In"

#### Task 5.3: Worker Logout Process
- [ ] Add logout button to worker dashboard
- [ ] Request location on logout
- [ ] Verify location (same as login)
- [ ] Record logout time and location
- [ ] Calculate work duration
- [ ] Update worker status to "Logged Out"
- [ ] Show summary (login time, logout time, duration, location)

---

### ✅ **PHASE 6: Provider Updates**

#### Task 6.1: Create LoginStatus Provider
- [ ] Create `lib/providers/login_status_provider.dart`
- [ ] Add methods:
  - `recordLogin(userId, location)`
  - `recordLogout(userId, location)`
  - `getLoginStatusByDate(date)`
  - `getLoginStatusByWorker(workerId)`
  - `getTodayLoginStatus()`
  - `getActiveWorkers()`
- [ ] Implement state management
- [ ] Add error handling

#### Task 6.2: Update User Provider
- [ ] Add method to get logged-in workers count
- [ ] Add method to get absent workers count
- [ ] Add method to update worker location
- [ ] Add method to check worker status

---

### ✅ **PHASE 7: Worker Dashboard Updates**

#### Task 7.1: Add Quick Access Cards
- [ ] Create card for "Request Advance"
  - Navigate to advance request screen
  - Show pending advance requests
- [ ] Create card for "View Salary"
  - Navigate to salary details
  - Show current month salary status
- [ ] Create card for "My Attendance"
  - Show today's login/logout status
  - Show current location
  - Show work duration

#### Task 7.2: Add Attendance Controls
- [ ] Add prominent "Mark Attendance" button (if not logged in)
- [ ] Add "Logout" button (if logged in)
- [ ] Show current status (Logged In/Logged Out)
- [ ] Show login time and duration (if logged in)
- [ ] Show current location

---

### ✅ **PHASE 8: Database Helper Updates**

#### Task 8.1: Add LoginStatus Methods
- [ ] `insertLoginStatus(LoginStatus status)`
- [ ] `updateLoginStatus(LoginStatus status)`
- [ ] `getLoginStatusByDate(String date)`
- [ ] `getLoginStatusByWorker(int workerId)`
- [ ] `getTodayLoginStatus()`
- [ ] `getActiveLoginStatus(int workerId)` - get current active login
- [ ] `getAllLoginStatus()`

#### Task 8.2: Update User Methods
- [ ] `updateUserLocation(int userId, double lat, double lng, String address)`
- [ ] `getUsersWithLocation()`
- [ ] Migration for adding location columns

---

### ✅ **PHASE 9: Advance & Salary Integration with Financial Tracking**

#### Task 9.1: Update Advance Model with Note/Purpose
- [ ] Add `note` field to Advance model (purpose of advance)
- [ ] Add `purpose` field to Advance model (category: Medical, Personal, Emergency, etc.)
- [ ] Update database schema to add note and purpose columns
- [ ] Update Advance model `toMap()` and `fromMap()` methods
- [ ] Add validation for note field (minimum characters)

#### Task 9.2: Advance-Salary Integration
- [ ] Add method to calculate total advance for a worker in a month
- [ ] Add method to get pending advance amount
- [ ] Update Salary model to include:
  - `advanceDeducted` field (amount deducted from salary)
  - `netSalary` field (totalSalary - advanceDeducted)
  - `advanceBalance` field (remaining advance if any)
- [ ] Update salary calculation logic to automatically deduct advances
- [ ] Show advance deduction breakdown in salary details

#### Task 9.3: Update Worker Dashboard Navigation
- [ ] Add navigation to Advance Request screen
- [ ] Add navigation to Salary Details screen
- [ ] Create AdvanceRequestScreen for workers
- [ ] Update MyAdvanceScreen to show request history with purpose/note
- [ ] Update MySalaryScreen to show detailed breakdown with advance deduction

#### Task 9.4: Create Advance Request Feature with Purpose
- [ ] Create form for workers to request advance
- [ ] Required fields: 
  - Amount
  - Purpose/Category dropdown (Medical, Personal, Emergency, Education, Family, Other)
  - Note/Reason (text area, minimum 10 characters)
  - Date needed
- [ ] Add validation for all fields
- [ ] Submit to admin for approval
- [ ] Show pending/approved/rejected status
- [ ] Send notification to admin (optional)

#### Task 9.5: Admin Advance Management
- [ ] Update SalaryAdvanceScreen to show advance with purpose/note
- [ ] Add approve/reject buttons for pending advances
- [ ] Show advance history with full details
- [ ] Add search/filter by purpose
- [ ] Show warning if advance exceeds salary limit

#### Task 9.6: Salary Calculation with Advance Deduction
- [ ] Create method to calculate monthly salary:
  ```dart
  totalSalary = dailyWage × workingDays
  totalAdvance = sum of all advances in month
  netSalary = totalSalary - totalAdvance
  ```
- [ ] Show negative balance if advance > salary
- [ ] Carry forward negative balance to next month
- [ ] Add alert for admin if worker has negative balance
- [ ] Update salary slip to show:
  - Gross Salary (dailyWage × days)
  - Advance Deducted (with breakdown)
  - Net Salary (Gross - Advance)
  - Advance Balance (if negative)

#### Task 9.7: Advance History & Tracking
- [ ] Show advance purpose/note in history
- [ ] Add status: Pending, Approved, Rejected, Deducted
- [ ] Show which salary period the advance was deducted from
- [ ] Add filter by status and purpose
- [ ] Show total advance taken vs deducted
- [ ] Add export to CSV with purpose/note

---

### ✅ **PHASE 10: Reports & Analytics**

#### Task 10.1: Update Reports Screen
- [ ] Add login/logout report
- [ ] Add location-based attendance report
- [ ] Add work duration summary
- [ ] Add export functionality for all reports

#### Task 10.2: Add Dashboard Analytics
- [ ] Add charts for attendance trends
- [ ] Add location map showing worker locations
- [ ] Add work duration analytics
- [ ] Add monthly summary widgets

---

### ✅ **PHASE 11: Settings & Configuration**

#### Task 11.1: Add Admin Settings
- [ ] Add setting for allowed location radius (meters)
- [ ] Add setting for work hours
- [ ] Add setting for auto-logout time
- [ ] Add setting for location tracking frequency
- [ ] Save settings in SharedPreferences

#### Task 11.2: Add Worker Settings
- [ ] Add setting to view registered location
- [ ] Add setting to request location update
- [ ] Add setting for notification preferences

---

### ✅ **PHASE 12: Testing & Validation**

#### Task 12.1: Unit Testing
- [ ] Test location service methods
- [ ] Test login status CRUD operations
- [ ] Test distance calculation
- [ ] Test location validation

#### Task 12.2: Integration Testing
- [ ] Test complete login flow with location
- [ ] Test logout flow with location
- [ ] Test admin viewing login status
- [ ] Test worker list with real-time updates

#### Task 12.3: UI Testing
- [ ] Test all new screens
- [ ] Test location permission flows
- [ ] Test error scenarios
- [ ] Test on different screen sizes

---

## 📊 PRIORITY ORDER

### **HIGH PRIORITY** (Week 1)
1. Database schema updates (Phase 1)
2. Location services setup (Phase 2)
3. Basic location in signup (Phase 4.1)
4. Status cards on admin home (Phase 3.1)

### **MEDIUM PRIORITY** (Week 2)
5. Worker list on admin home (Phase 3.2)
6. Login with location verification (Phase 5.1, 5.2)
7. Logout with location (Phase 5.3)
8. LoginStatus provider (Phase 6.1)

### **NORMAL PRIORITY** (Week 3)
9. Replace attendance screen (Phase 3.3)
10. Worker dashboard updates (Phase 7)
11. Advance & salary access (Phase 9)
12. Database helper updates (Phase 8)

### **LOW PRIORITY** (Week 4)
13. Reports & analytics (Phase 10)
14. Settings & configuration (Phase 11)
15. Testing (Phase 12)

---

## 🔧 TECHNICAL REQUIREMENTS

### Dependencies to Add:
```yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  permission_handler: ^11.1.0
  flutter_map: ^6.1.0 # Optional: for map display
```

### Platform Permissions:

#### Android (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

#### iOS (`Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location to verify your attendance location</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location to track attendance</string>
```

---

## 📝 NOTES

1. **Location Accuracy**: Use GPS for accurate location tracking
2. **Battery Optimization**: Only track location during login/logout
3. **Privacy**: Store location data securely, inform users
4. **Offline Support**: Cache location data if offline, sync when online
5. **Error Handling**: Handle GPS disabled, permission denied scenarios
6. **Distance Calculation**: Use Haversine formula for accuracy
7. **Default Radius**: Start with 100 meters, make it configurable

---

## 🎯 SUCCESS CRITERIA

- ✅ Workers can only login/logout from registered location
- ✅ Admin can see real-time employee status (logged in/absent)
- ✅ Login/logout times and locations are recorded
- ✅ Worker list shows on admin home screen
- ✅ Workers can access advance and salary features
- ✅ Location verification works accurately
- ✅ All data persists in local database
- ✅ CSV export includes location data

---

## 🚀 NEXT STEPS

1. Review and approve this task list
2. Start with Phase 1 (Database Schema Updates)
3. Implement features in priority order
4. Test each phase before moving to next
5. Update this document as tasks are completed

---

**Last Updated**: 2025-10-29
**Status**: Planning Phase
**Estimated Completion**: 4 weeks

