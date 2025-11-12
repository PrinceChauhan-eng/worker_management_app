# Login Testing Instructions

## Overview
This document provides instructions for testing the login functionality after the Supabase migration and interface updates.

## Common Login Issues and Solutions

### 1. "Invalid credentials" Error
This is the most common error after migration. It typically occurs because:

1. **No users exist in the database** - You need to create at least one user
2. **Incorrect authentication logic** - Fixed in the latest update

### 2. How to Create Test Users

#### Option A: Using the Sign Up Screen
1. Open the application
2. On the login screen, click "Sign Up"
3. Fill in the required information:
   - Name: Admin User
   - Phone: 9876543210
   - Email: admin@example.com
   - Password: admin123
   - Role: Admin
   - Wage: 0
   - Join Date: Today's date
4. Click "Sign Up"
5. After successful registration, return to the login screen

#### Option B: Manual Database Entry (Advanced)
If you have access to your Supabase dashboard:
1. Go to your Supabase project
2. Navigate to Table Editor
3. Select the "users" table
4. Click "Insert row"
5. Fill in the required fields:
   - name: Admin User
   - phone: 9876543210
   - email: admin@example.com
   - password: admin123 (Note: In production, this should be hashed)
   - role: admin
   - wage: 0
   - join_date: YYYY-MM-DD format (e.g., 2025-11-10)

### 3. Testing Login

#### Test Case 1: Admin Login with Email
1. Open the application
2. Enter the following credentials:
   - Identifier: admin@example.com
   - Password: admin123
   - Role: Admin
3. Click "Login"
4. ✅ Expected: Should navigate to Admin Dashboard

#### Test Case 2: Admin Login with Phone
1. Open the application
2. Enter the following credentials:
   - Identifier: 9876543210
   - Password: admin123
   - Role: Admin
3. Click "Login"
4. ✅ Expected: Should navigate to Admin Dashboard

#### Test Case 3: Worker Login
1. Create a worker user (using Sign Up or manual entry)
2. Enter the worker credentials:
   - Identifier: worker email or phone
   - Password: worker password
   - Role: Worker
3. Click "Login"
4. ✅ Expected: Should navigate to Worker Dashboard

## Troubleshooting

### If Login Still Fails:

1. **Check Internet Connection**
   - Ensure you have a stable internet connection
   - The app needs to connect to Supabase

2. **Check Supabase Configuration**
   - Verify the Supabase URL and anon key in main.dart
   - Ensure they match your Supabase project settings

3. **Check Console Logs**
   - Look for error messages in the console
   - Common errors include:
     - Network connection issues
     - Invalid Supabase credentials
     - Database permission errors

4. **Verify User Exists**
   - Check that the user actually exists in the database
   - Verify the email/phone and role match exactly

### Error Messages and Meanings:

- **"Invalid credentials"**: Username/password/role combination is incorrect
- **"No users found in database"**: Database is empty, need to create users
- **"Login failed. Please try again."**: Generic error, check console for details

## Recent Fixes Applied

The following fixes have been implemented to resolve login issues:

1. **Added getUserByEmail method** to UsersService for efficient email lookup
2. **Updated login logic** to use direct database queries instead of fetching all users
3. **Improved error handling** with better user feedback
4. **Enhanced validation** for email, phone, and ID inputs

## Next Steps

1. Try the login with the test credentials above
2. If successful, test all user flows (admin and worker)
3. If still failing, check the console logs for specific error messages
4. Contact support with detailed error information if issues persist

## Support

If you continue to experience issues:
1. Take a screenshot of the error
2. Copy any console error messages
3. Note the exact steps you took
4. Provide this information for further assistance