# Worker Management App

A comprehensive Flutter application for managing workers, attendance, payroll, and advances in a workplace environment.

## Project Structure

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart
├── models/
│   ├── user.dart
│   ├── attendance.dart
│   ├── advance.dart
│   ├── salary.dart
│   ├── login_status.dart
│   └── notification.dart
├── providers/
│   ├── user_provider.dart
│   ├── auth_provider.dart
│   ├── attendance_provider.dart
│   ├── advance_provider.dart
│   ├── salary_provider.dart
│   ├── login_status_provider.dart
│   └── notification_provider.dart
├── services/
│   ├── supabase_service.dart
│   ├── auth_service.dart
│   ├── attendance_service.dart
│   ├── advance_service.dart
│   ├── salary_service.dart
│   ├── login_status_service.dart
│   ├── notification_service.dart
│   ├── session_manager.dart
│   ├── database_updater.dart
│   └── location_table_updater.dart
├── utils/
│   ├── logger.dart
│   ├── csv_exporter.dart
│   ├── excel_exporter.dart
│   ├── pdf_generator.dart
│   └── export_utils.dart
├── widgets/
│   ├── live_clock.dart
│   ├── summary_card.dart
│   ├── dashboard_summary_row.dart
│   ├── enhanced_dashboard_card.dart
│   ├── enhanced_attendance_card.dart
│   ├── shimmer_loading.dart
│   ├── skeleton_card.dart
│   ├── custom_app_bar.dart
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── profile_menu_button.dart
│   ├── quick_action_menu.dart
│   ├── hover_toggle_button.dart
│   ├── salary_slip_dialog.dart
│   └── live_clock.dart
└── screens/
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── admin/
    │   ├── dashboard_home_screen.dart
    │   ├── worker_attendance_screen.dart
    │   ├── advance_management_screen.dart
    │   ├── process_salary_screen.dart
    │   └── worker_list_screen.dart
    ├── worker/
    │   ├── worker_dashboard_screen.dart
    │   ├── my_attendance_screen.dart
    │   ├── my_salary_screen.dart
    │   └── my_advance_screen.dart
    ├── reports_screen.dart
    └── settings_screen.dart
```

## Key Features

### 1. Authentication & User Management
- Role-based access control (Admin/Worker)
- Secure login/logout functionality
- User profile management
- Session management

### 2. Dashboard
- Real-time clock display
- Statistics overview (Total Workers, Logged In, Absent)
- Quick action cards for daily tasks
- Worker attendance sessions with pagination

### 3. Attendance Management
- Real-time login/logout tracking
- GPS location capture on login/logout
- Attendance history with timeline view
- Manual attendance editing
- Search, filter, and sort functionality
- 12-hour time format display
- Status badges (Present, Logged In, Absent)

### 4. Advance Management
- Request and track worker advances
- Advance history with pagination
- Purpose and note fields for advances
- Balance tracking

### 5. Payroll Processing
- Automated salary calculation
- Monthly salary processing
- Salary history tracking

### 6. Reporting
- Attendance reports
- Salary reports
- Advance reports
- Export functionality (CSV, Excel, PDF)
- Live summary metrics
- Search, filter, and sort capabilities

### 7. Notifications
- In-app notifications for attendance updates
- Salary generation notifications
- Deep linking from notifications
- Notification badges

### 8. Settings
- Language selection (English, Hindi, Gujarati)
- Theme selection (Light/Dark/System)
- Profile management

## Technical Features

### UI/UX Enhancements
- Responsive design for all screen sizes
- Smooth animations and transitions
- Consistent styling with rounded corners and shadows
- Loading skeletons for better perceived performance
- Real-time auto-refresh via WebSocket subscriptions

### Data Management
- Supabase backend integration
- Real-time data synchronization
- Offline support considerations
- Data export capabilities (CSV, Excel, PDF)

### Security
- Secure authentication with Supabase Auth
- Role-based access control
- Data validation and sanitization

## Modules Implementation

### Module A - Export/Reports
- **Phase A1**: Reusable CSV/Excel export utilities
- **Phase A2**: Admin export UI with monthly dropdown
- **Phase A3**: Auto-filtered export per site (optional)
- **Phase A4**: Archive history functionality

### Module B - Better In-App Notifications
- **Phase B1**: Auto notifications for attendance edit
- **Phase B2**: Auto notifications for salary generation
- **Phase B3**: Notification badge + list
- **Phase B4**: Deep links inside app

### Module C - Location on Login/Logout
- **Phase C1**: Permissions + GPS fetching
- **Phase C2**: Store location in attendance logs
- **Phase C3**: Admin UI show full timeline

## Admin Dashboard Features
- Live real-time clock
- Worker attendance sessions with pagination
- Quick action cards:
  - Edit Attendance
  - Advance Management
  - Process Payroll
  - Reports
- Search, filter, and sort worker attendance
- Direct navigation to worker details

## Worker Dashboard Features
- Live real-time clock
- Big login/logout button
- Live work duration timer
- Today's timeline card
- Quick access to personal attendance, salary, and advance information

## Technologies Used
- Flutter Framework
- Supabase (Backend-as-a-Service)
- Provider State Management
- Google Fonts
- PDF, CSV, and Excel generation libraries
- Geolocation and geocoding packages

## Setup Instructions
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Supabase credentials in `main.dart`
4. Run `flutter run` to start the application

## Contributing
This project is maintained specifically for the owner's use case. Contributions are not accepted at this time.

## License
This project is proprietary and confidential. All rights reserved.