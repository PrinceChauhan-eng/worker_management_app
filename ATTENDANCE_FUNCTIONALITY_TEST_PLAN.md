# Attendance Functionality Test Plan

## Overview
This document outlines the test plan to verify that the attendance functionality is working correctly after the recent fixes.

## Test Scenarios

### 1. Admin Marks Worker as Present
**Steps:**
1. Navigate to Worker Attendance screen
2. Select a worker
3. Select a date
4. Click "Mark Present"
5. Verify success message is displayed
6. Check dashboard statistics
7. Generate reports
8. Verify worker shows as present in both dashboard and reports

**Expected Results:**
- Success message: "Marked as PRESENT for [date]"
- Dashboard "Absent" count should NOT include this worker
- Reports should show this worker as present
- Both LoginStatus and Attendance records should be updated

### 2. Admin Marks Worker as Absent
**Steps:**
1. Navigate to Worker Attendance screen
2. Select a worker
3. Select a date
4. Click "Mark Absent"
5. Verify success message is displayed
6. Check dashboard statistics
7. Generate reports
8. Verify worker shows as absent in both dashboard and reports

**Expected Results:**
- Success message: "Marked as ABSENT for [date]"
- Dashboard "Absent" count SHOULD include this worker
- Reports should show this worker as absent
- Both LoginStatus and Attendance records should be updated

### 3. Admin Updates Existing Attendance Record
**Steps:**
1. Mark a worker as present for a specific date
2. Verify the record is created
3. Mark the same worker as absent for the same date
4. Verify the record is updated
5. Check dashboard statistics
6. Generate reports

**Expected Results:**
- Record should be updated, not duplicated
- Dashboard statistics should reflect the change
- Reports should show the updated status

### 4. Multiple Workers Attendance
**Steps:**
1. Mark multiple workers as present
2. Mark multiple workers as absent
3. Check dashboard statistics
4. Generate reports

**Expected Results:**
- All workers should be correctly tracked
- Dashboard statistics should show correct counts
- Reports should show correct attendance status for all workers

## Verification Points

### Dashboard Statistics
- Total workers count should remain consistent
- "Logged In" count should reflect currently logged in workers
- "Absent" count should reflect workers marked as absent by admin

### Reports
- Attendance records should match what was marked by admin
- Present workers should be counted in totalAttendanceDays
- Absent workers should NOT be counted in totalAttendanceDays

### Database Records
- Both login_status and attendance tables should be synchronized
- No duplicate records should be created
- Records should be properly updated when status changes

## Test Data Preparation
1. Create test workers in the database
2. Ensure no existing attendance records for test dates
3. Prepare test dates (today and a few past dates)

## Test Execution

### Test 1: Mark Worker as Present
1. Open Worker Attendance screen
2. Select Worker A
3. Select today's date
4. Click "Mark Present"
5. Observe: Success message displayed
6. Navigate to Dashboard
7. Observe: Absent count should NOT include Worker A
8. Navigate to Reports
9. Generate report for current month
10. Observe: Worker A should show as present

### Test 2: Mark Worker as Absent
1. Open Worker Attendance screen
2. Select Worker B
3. Select today's date
4. Click "Mark Absent"
5. Observe: Success message displayed
6. Navigate to Dashboard
7. Observe: Absent count SHOULD include Worker B
8. Navigate to Reports
9. Generate report for current month
10. Observe: Worker B should show as absent

### Test 3: Update Existing Record
1. Mark Worker C as present for a specific date
2. Verify record is created
3. Mark Worker C as absent for the same date
4. Verify record is updated (not duplicated)
5. Check dashboard and reports
6. Observe: Status should reflect "absent"

## Expected Issues to Watch For
1. Synchronization issues between LoginStatus and Attendance systems
2. Dashboard statistics not refreshing automatically
3. Reports showing incorrect attendance status
4. Duplicate records being created
5. Error messages when marking attendance

## Success Criteria
- All attendance marking operations succeed
- Dashboard statistics accurately reflect attendance status
- Reports accurately reflect attendance status
- Both LoginStatus and Attendance records are properly synchronized
- No errors or exceptions during testing

## Rollback Plan
If issues are found:
1. Revert changes to WorkerAttendanceScreen
2. Restore previous version of attendance synchronization logic
3. Document issues found for future fixes