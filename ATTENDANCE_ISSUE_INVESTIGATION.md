# Attendance Issue Investigation

## Issues Reported

1. **Duplicate Worker Count Issue**: When the same worker is marked present by admin 2 times, it should still count as 1 worker
2. **Incorrect Absent Count**: Only 2 workers in database but showing 6 absent workers
3. **Toggle Functionality Issue**: Success message says "saved attendance successfully" but it marks as Absent

## Investigation Plan

### Step 1: Check Database Records
1. Check if there are duplicate login_status records for the same worker on the same date
2. Check if there are duplicate attendance records for the same worker on the same date
3. Verify the total number of unique workers in the database

### Step 2: Check Statistics Calculation
1. Verify the logic in `getLoginStatistics()` method
2. Check how workers are being counted
3. Check how absent workers are being counted

### Step 3: Check Toggle Functionality
1. Verify the EnhancedAttendanceScreen toggle logic
2. Check how the present/absent status is being saved
3. Verify the UI feedback after saving

### Step 4: Check WorkerAttendanceScreen
1. Verify the synchronization between LoginStatus and Attendance systems
2. Check for duplicate record creation
3. Verify the success message logic

## Database Structure Analysis

### users table
- Should contain unique workers
- Filtered by role = 'worker' for statistics

### login_status table
- Should have unique records per worker_id + date combination
- Uses upsert with onConflict: 'worker_id,date'

### attendance table
- Should have unique records per worker_id + date combination
- Currently uses insert/update instead of upsert

## Potential Issues Identified

### 1. Duplicate Records
- Possible duplicate records in login_status or attendance tables
- Could cause incorrect worker counts

### 2. Statistics Calculation Logic
- May be counting duplicate records
- May have incorrect logic for determining absent workers

### 3. Toggle UI/Logic Mismatch
- UI might show one state but save another
- Could be a display vs. data issue

### 4. Inconsistent Data Between Systems
- LoginStatus and Attendance systems might not be properly synchronized
- Could lead to inconsistent reporting

## Testing Steps

### Database Verification
1. Query users table to count unique workers with role = 'worker'
2. Query login_status table to check for duplicate records
3. Query attendance table to check for duplicate records

### Statistics Verification
1. Manually calculate expected absent count
2. Compare with actual statistics from getLoginStatistics()
3. Check each step of the calculation logic

### Toggle Functionality Verification
1. Test toggle ON/OFF states
2. Verify saved data matches UI state
3. Check success message accuracy

### Synchronization Verification
1. Check that LoginStatus and Attendance records are consistent
2. Verify both systems are updated together
3. Test edge cases like network failures

## Expected vs Actual Behavior

### Worker Count
- Expected: Number of unique workers with role = 'worker'
- Actual: Currently showing incorrect count

### Absent Count
- Expected: Number of workers with login_status records where is_logged_in = false
- Actual: Showing 6 absent when only 2 workers exist

### Toggle Behavior
- Expected: Toggle ON = Present, Toggle OFF = Absent, Save success message accurate
- Actual: Success message says "saved" but marks as Absent

## Next Steps

1. Implement database verification queries
2. Fix any duplicate record issues
3. Correct statistics calculation logic
4. Fix toggle functionality issues
5. Ensure proper synchronization between systems