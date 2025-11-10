# Worker Management App - Troubleshooting Guide

## Common Login Issues and Solutions

### 1. "An error occurred. Please try again." Error

This is a generic error message that can have several underlying causes:

#### Potential Causes:
1. **Database initialization issues**
2. **Network connectivity problems**
3. **Corrupted session data**
4. **Missing database tables or columns**
5. **Permission issues**

#### Diagnostic Steps:

1. **Check Console Logs**
   - Run the app with `flutter run` to see detailed error messages
   - Look for error messages starting with `=== LOGIN ERROR ===` or `=== SPLASH SCREEN ERROR ===`

2. **Verify Database State**
   ```bash
   # Check if database file exists
   # On Windows, database is typically located at:
   # C:\Users\[Username]\AppData\Local\[App Name]\worker_management.db
   ```

3. **Clear App Data**
   - Uninstall and reinstall the app
   - Or clear app data from device settings

4. **Test with Default Credentials**
   - Phone: `8104246218`
   - Password: `admin123`
   - Role: `Admin`

### 2. Database Issues

#### Symptoms:
- App crashes on startup
- Unable to login with any credentials
- "Database error" messages

#### Solutions:
1. **Force Database Reinitialization**
   - The app automatically tries to upgrade the database on startup
   - Check console for "Database upgrade completed successfully" message

2. **Check Database Schema**
   - Ensure all required tables exist:
     - users
     - attendance
     - advance
     - salary
     - login_status
     - login_history
     - notifications

3. **Verify Table Columns**
   - Each table should have all required columns as defined in `database_helper.dart`

### 3. Session Management Issues

#### Symptoms:
- App redirects to login screen unexpectedly
- "Session expired" behavior
- Inconsistent user state

#### Solutions:
1. **Clear Session Data**
   - The app provides a logout function that clears session data
   - Manually clear SharedPreferences data if needed

2. **Check "Remember Me" Functionality**
   - If "Remember Me" is enabled, the app tries to auto-login with stored credentials
   - Disable "Remember Me" to force manual login

### 4. Environment Issues

#### Symptoms:
- App works on one machine but not another
- Build errors
- Runtime errors not seen on development machine

#### Solutions:
1. **Verify Flutter Setup**
   ```bash
   flutter doctor
   ```

2. **Check Dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Environment Variables** (Based on project memory)
   - Ensure `TEMP` and `TMP` are set to `D:\Temp`
   - Ensure `PUB_CACHE` is set to `D:\FlutterCache\.pub-cache`

## Debugging Steps

### 1. Enable Detailed Logging
The app includes extensive logging. When running the app, pay attention to:
- Database initialization messages
- User authentication logs
- Session management logs
- Error messages with stack traces

### 2. Test Database Connectivity
In the app's main.dart, there's a database force upgrade mechanism:
```dart
// Force database upgrade to ensure all columns exist
try {
  final dbHelper = DatabaseHelper();
  await dbHelper.forceUpgrade();
  print('Database upgrade completed successfully');
} catch (e) {
  print('Error during database upgrade: $e');
}
```

### 3. Verify User Credentials
Check that the user exists in the database with the correct:
- Phone number
- Password (hashed)
- Role

### 4. Check Network Permissions
Ensure the app has necessary permissions for:
- Storage access
- Network connectivity (if using remote services)

## Recovery Procedures

### 1. Reset Database
If the database is corrupted:
1. Uninstall the app
2. Reinstall the app
3. The app will create a fresh database with default admin user

### 2. Clear Session Data
To clear session data programmatically:
1. Use the logout function in the app
2. Or clear SharedPreferences manually

### 3. Reinstall Dependencies
If there are dependency issues:
```bash
flutter clean
flutter pub get
flutter run
```

## Contact Support

If none of the above solutions work:
1. Capture the full console log output
2. Note the exact steps that lead to the error
3. Include device/platform information
4. Contact the development team with this information

## Default Credentials

For testing purposes, the app creates a default admin user:
- Phone: `8104246218`
- Password: `admin123`
- Role: `admin`

## Version Information

Current database version: 6
Last updated: Based on database_helper.dart implementation