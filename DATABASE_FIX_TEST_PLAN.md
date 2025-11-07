# Database Fix Test Plan

## Objective
Verify that the database initialization fix resolves the "no such table: notifications" error for both admin and worker logins.

## Test Cases

### Test Case 1: Fresh Database Initialization
1. Clear browser data/cache completely
2. Run the app from scratch
3. Verify that all database tables are created properly including notifications table
4. Login as admin (8104246218 / admin123)
5. Check that no database errors occur
6. Navigate to different sections to verify functionality

### Test Case 2: Existing Database Upgrade
1. If possible, simulate an older database version
2. Verify that the notifications table is created during upgrade
3. Test admin login
4. Test worker login
5. Verify notifications functionality works

### Test Case 3: Notifications Functionality
1. Login as admin
2. Perform actions that should generate notifications:
   - Process a salary
   - Approve an advance request
3. Check that notifications are created and can be retrieved
4. Verify notification count updates correctly
5. Test marking notifications as read

### Test Case 4: Worker Login
1. Login as a worker
2. Verify that notifications can be loaded for the worker
3. Check that notification count is displayed correctly
4. Verify no database errors occur

### Test Case 5: Cross-Session Persistence
1. Login and perform some actions that generate notifications
2. Logout and close the app
3. Reopen and login again
4. Verify that notifications persist across sessions
5. Check that unread notification counts are correct

## Expected Results
- No "no such table: notifications" errors should occur
- Database should initialize properly with all required tables
- Notifications functionality should work for both admin and worker roles
- Data should persist across sessions
- All existing functionality should continue to work as expected

## Test Status
- [ ] Fresh Database Initialization - PASSED/FAILED
- [ ] Existing Database Upgrade - PASSED/FAILED
- [ ] Notifications Functionality - PASSED/FAILED
- [ ] Worker Login - PASSED/FAILED
- [ ] Cross-Session Persistence - PASSED/FAILED

## Additional Notes
- If errors persist, check browser console for detailed error messages
- Verify that the database version is correctly set to 3
- Check that all table creation and upgrade logic is working properly