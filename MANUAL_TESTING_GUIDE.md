# Manual Testing Guide for Supabase Migration

## Overview
This guide provides step-by-step instructions to manually verify that all functionality in the Worker Management App is working properly after the migration to Supabase.

## Prerequisites
1. Ensure the application is built and running
2. Have access to the Supabase project
3. Have test credentials for both admin and worker accounts

## Testing Procedure

### 1. User Authentication Flow

#### 1.1 Admin Login
1. Open the application
2. On the login screen, enter:
   - Identifier: Admin email or phone
   - Password: Admin password
   - Role: Select "Admin"
3. Click "Login"
4. ✅ Verify: Should navigate to Admin Dashboard

#### 1.2 Worker Login
1. Logout from admin account
2. On the login screen, enter:
   - Identifier: Worker email or phone
   - Password: Worker password
   - Role: Select "Worker"
3. Click "Login"
4. ✅ Verify: Should navigate to Worker Dashboard

#### 1.3 Sign Up Flow
1. On login screen, click "Sign Up"
2. Fill in all required fields:
   - Name
   - Phone number
   - Email
   - Password
   - Role
   - Wage
   - Join Date
3. Click "Sign Up"
4. ✅ Verify: Account is created and can be used for login

### 2. Admin Dashboard Functionality

#### 2.1 Worker Management
1. Navigate to "Workers" section
2. ✅ Verify: Can view list of all workers
3. Click "Add Worker"
4. Fill in worker details
5. Click "Save"
6. ✅ Verify: New worker appears in the list
7. Select a worker and click "Edit"
8. Modify some details
9. Click "Save"
10. ✅ Verify: Worker details are updated
11. Select a worker and click "Delete"
12. ✅ Verify: Worker is removed from the list

#### 2.2 Attendance Monitoring
1. Navigate to "Attendance" section
2. ✅ Verify: Can view attendance records for all workers
3. Filter by date/worker
4. ✅ Verify: Filter works correctly
5. Click "Edit" on an attendance record
6. Modify status or time
7. Click "Save"
8. ✅ Verify: Changes are reflected

#### 2.3 Salary Processing
1. Navigate to "Salary" section
2. ✅ Verify: Can view salary records
3. Click "Process Salary" for a worker
4. Enter required details
5. Click "Save"
6. ✅ Verify: Salary record is created
7. View salary slip
8. ✅ Verify: Salary slip displays correctly

#### 2.4 Advance Request Management
1. Navigate to "Advance" section
2. ✅ Verify: Can view all advance requests
3. Select a pending request
4. Click "Approve" or "Reject"
5. ✅ Verify: Request status is updated

### 3. Worker Dashboard Functionality

#### 3.1 Attendance Marking
1. Navigate to "Attendance" section
2. Click "Mark Attendance"
3. ✅ Verify: Attendance is recorded for current date
4. Check attendance history
5. ✅ Verify: Shows complete attendance record

#### 3.2 Salary Viewing
1. Navigate to "Salary" section
2. ✅ Verify: Can view salary history
3. Click on a salary record
4. ✅ Verify: Salary slip displays correctly

#### 3.3 Advance Requests
1. Navigate to "Advances" section
2. Click "Request Advance"
3. Enter amount and reason
4. Click "Submit"
5. ✅ Verify: Request appears in advance history
6. Check request status
7. ✅ Verify: Status updates correctly

### 4. Profile Management

#### 4.1 Profile Editing (Admin/Worker)
1. Click on profile icon/menu
2. Select "Profile"
3. Click "Edit Profile"
4. Modify profile details
5. Click "Save"
6. ✅ Verify: Changes are saved and displayed

#### 4.2 Settings
1. Navigate to "Settings"
2. ✅ Verify: All settings options are accessible
3. Test notification settings
4. ✅ Verify: Settings are saved correctly

### 5. Data Synchronization Verification

#### 5.1 Cross-Device Consistency
1. Perform an action on one device (e.g., mark attendance)
2. Check the same data on another device/browser
3. ✅ Verify: Data is consistent across devices

#### 5.2 Real-time Updates
1. Have two users logged in simultaneously
2. Perform an action with one user
3. ✅ Verify: Second user sees updates without refresh

### 6. Error Handling

#### 6.1 Network Issues
1. Disconnect from internet
2. Try to perform an action
3. ✅ Verify: Appropriate error message is shown
4. Reconnect to internet
5. ✅ Verify: App resumes normal operation

#### 6.2 Invalid Inputs
1. Try to submit forms with invalid data
2. ✅ Verify: Proper validation messages are shown
3. Try to login with incorrect credentials
4. ✅ Verify: Appropriate error message is displayed

## Expected Results

### ✅ All Tests Should Pass:
- User authentication works for both roles
- Admin can manage all aspects of the system
- Workers can view and update their own information
- Data is consistent across devices
- Error handling is appropriate
- Performance is acceptable
- Security measures are in place

## Troubleshooting

### Common Issues and Solutions:

1. **Login Failures**
   - Check that user exists in Supabase
   - Verify password is correct
   - Ensure role is selected correctly

2. **Data Not Loading**
   - Check internet connection
   - Verify Supabase project URL and anon key
   - Check browser console for errors

3. **Slow Performance**
   - Check network connectivity
   - Verify Supabase project is not rate-limited
   - Check for large data sets causing delays

4. **Permission Errors**
   - Verify RLS (Row Level Security) policies in Supabase
   - Check user roles and permissions
   - Ensure proper authentication state

## Conclusion

After completing all the tests in this guide, you should be able to confirm that:

1. ✅ All database operations work with Supabase
2. ✅ No references to DatabaseHelper remain
3. ✅ All user flows function correctly
4. ✅ Data is properly synchronized
5. ✅ Error handling is appropriate
6. ✅ Application is ready for production use

If all tests pass, the migration to Supabase has been successfully completed and all functionality is working properly.