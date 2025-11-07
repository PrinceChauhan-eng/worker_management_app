# Issue Fix Plan

## Problems Identified

1. **Database Error**: "no such table: notifications" error occurring for both admin and worker logins
2. **Worker Count Issue**: Dashboard showing 3 workers instead of 2
3. **Admin Attendance Edit Sync**: Changes made by admin in attendance editing not reflecting in worker dashboard

## Root Causes

### Issue 1: Database Error
- Notifications table verification was added but had a typo
- The typo has been fixed in database_helper.dart

### Issue 2: Worker Count Issue
- Need to check the actual database content to see what users exist
- The statistics calculation in LoginStatusProvider might be counting incorrectly

### Issue 3: Admin Attendance Edit Sync
- The updateLoginStatus method in LoginStatusProvider only reloads data for a specific worker
- It doesn't update the global state that the worker dashboard listens to
- The worker dashboard needs to refresh its login status when admin makes changes

## Fix Implementation Plan

### Fix 1: Database Error (COMPLETED)
- ✓ Fixed typo in database_helper.dart notifications table creation
- ✓ Added notifications table verification in _onOpen method

### Fix 2: Worker Count Issue
- [ ] Check database content to identify extra user
- [ ] Verify getUsers method in database_helper.dart
- [ ] Check login statistics calculation in LoginStatusProvider
- [ ] Ensure only users with role 'worker' are counted

### Fix 3: Admin Attendance Edit Sync
- [ ] Modify updateLoginStatus method to notify all relevant listeners
- [ ] Add mechanism for worker dashboard to refresh when admin makes changes
- [ ] Implement real-time sync between admin and worker views

## Detailed Implementation Steps

### For Worker Count Issue:
1. Add debugging to print all users in database
2. Verify that only users with role 'worker' are counted in statistics
3. Check if there's an admin user being counted as a worker
4. Ensure proper filtering in getLoginStatistics method

### For Admin Attendance Edit Sync:
1. Modify LoginStatusProvider.updateLoginStatus to broadcast changes globally
2. Add a refresh mechanism in worker dashboard to check for updates
3. Implement a notification system or polling to keep worker dashboard in sync

## Test Plan

### Test Case 1: Database Fix Verification
- Clear browser data
- Run app from scratch
- Login as admin
- Verify no database errors occur
- Check that notifications functionality works

### Test Case 2: Worker Count Verification
- Login as admin
- Check dashboard statistics
- Verify worker list shows correct count
- Check database content to confirm user roles

### Test Case 3: Attendance Edit Sync Verification
- Login as worker and mark login
- Login as admin and edit worker's attendance
- Verify worker dashboard reflects the changes
- Check that worker status updates correctly

## Files to Modify

1. `lib/services/database_helper.dart` - Add debugging for user retrieval
2. `lib/providers/login_status_provider.dart` - Fix updateLoginStatus method
3. `lib/screens/worker_dashboard_screen.dart` - Add refresh mechanism

## Expected Results

- No more database errors
- Correct worker count displayed (2 workers)
- Admin attendance edits reflected in worker dashboard in real-time
- All existing functionality continues to work as expected