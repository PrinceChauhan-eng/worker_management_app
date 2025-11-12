# Manual Database Testing Guide

## Overview
This guide provides step-by-step instructions for manually testing the database migration implementation to ensure all components work correctly.

## Prerequisites
1. Supabase project with valid credentials
2. Flutter development environment set up
3. Application configured with Supabase connection details
4. Access to Supabase dashboard for verification

## Testing Steps

### Step 1: Prepare Test Environment
1. Ensure your Supabase project is accessible
2. Verify that your `main.dart` file includes the database migration code:
   ```dart
   // Run database migrations
   try {
     final databaseUpdater = DatabaseUpdater();
     await databaseUpdater.runMigrations();
     Logger.info('Database migrations completed successfully');
   } catch (e) {
     Logger.error('Failed to run database migrations: $e', e);
   }
   ```
3. Make sure no existing tables exist in your Supabase database (for clean test)

### Step 2: Run Initial Migration Test
1. Start the application
2. Monitor the console/logs for migration messages:
   - "Starting database migrations..."
   - "Users table migration completed"
   - "Attendance table migration completed"
   - etc.
3. Check for any error messages in the logs

### Step 3: Verify Database Schema in Supabase Dashboard
1. Log into your Supabase dashboard
2. Navigate to the Table Editor
3. Verify that all 6 tables have been created:
   - `users`
   - `attendance`
   - `login_status`
   - `advance`
   - `salary`
   - `notifications`

### Step 4: Check Users Table Structure
1. Click on the `users` table
2. Verify the following columns exist:
   - `work_location_latitude` (double precision)
   - `work_location_longitude` (double precision)
   - `work_location_address` (text)
   - `location_radius` (double precision)
   - `profile_photo` (text)
   - `id_proof` (text)
   - `email_verified` (boolean)
   - `email_verification_code` (text)
   - `designation` (text)

### Step 5: Check Login Status Table Structure
1. Click on the `login_status` table
2. Verify the following columns exist:
   - `city` (text)
   - `state` (text)
   - `pincode` (text)
   - `country` (text)
   - `logout_city` (text)
   - `logout_state` (text)
   - `logout_pincode` (text)

### Step 6: Verify RLS Policies
1. For each table, check that RLS is enabled
2. Verify that the following policies exist:
   - `{table_name}_select` - SELECT using (true)
   - `{table_name}_insert` - INSERT with check (true)
   - `{table_name}_update` - UPDATE using (true) with check (true)
   - `{table_name}_delete` - DELETE using (true)

### Step 7: Test Application Functionality
1. Try to create a new user through the application
2. Verify that all user fields can be saved correctly
3. Test the login/logout functionality
4. Verify that location data is captured and stored
5. Test advance request functionality
6. Test salary processing features
7. Test notification system

### Step 8: Test Schema Update Scenario
1. If you already have data in your database:
   - Run the application again
   - Verify that new columns are added without data loss
   - Confirm existing data remains intact

### Step 9: Error Handling Test
1. Temporarily disconnect from the internet
2. Try to run the application
3. Verify that appropriate error messages are logged
4. Confirm that the application doesn't crash

### Step 10: Performance Test
1. Measure how long the migrations take on first run
2. Measure how long subsequent runs take
3. Verify that the application starts normally after migrations

## Expected Results

### Successful Migration
- All 6 tables created successfully
- All required columns present in each table
- RLS policies applied correctly
- No error messages in logs
- Application functions normally

### Data Integrity
- No existing data lost during migration
- All existing records accessible after migration
- New fields properly initialized (nullable or with defaults)

### Performance
- First run: Migration completes within 5 seconds
- Subsequent runs: Migration completes within 1 second
- Application startup time not significantly impacted

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Connection failed" errors
**Solution**: 
1. Verify Supabase credentials in `main.dart`
2. Check internet connectivity
3. Confirm Supabase project is accessible

#### Issue: "Permission denied" errors
**Solution**:
1. Check Supabase database permissions
2. Verify that the user has sufficient privileges
3. Ensure RLS policies are correctly applied

#### Issue: "Table already exists" errors
**Solution**:
1. This should not happen with `IF NOT EXISTS` clauses
2. Check that the migration SQL uses proper syntax
3. Verify database updater code

#### Issue: Missing columns after migration
**Solution**:
1. Check that the migration completed successfully
2. Verify SQL syntax for adding columns
3. Confirm that the application was restarted after code changes

### Log Analysis
1. Look for "Starting database migrations..." message
2. Check for individual table completion messages
3. Watch for any error messages
4. Verify "All database migrations completed successfully" message

## Verification Checklist

### Database Schema
- [ ] All 6 tables exist
- [ ] Users table has all new location fields
- [ ] Login status table has city/state/pincode fields
- [ ] All other tables have correct structure
- [ ] RLS policies applied to all tables

### Application Functionality
- [ ] User creation works with new fields
- [ ] Login/logout captures location data
- [ ] Advance requests process correctly
- [ ] Salary calculations accurate
- [ ] Notifications function properly

### Error Handling
- [ ] Network errors handled gracefully
- [ ] Database errors logged appropriately
- [ ] Application remains stable
- [ ] Recovery procedures work

### Performance
- [ ] Migration time within acceptable limits
- [ ] No memory leaks
- [ ] Application startup not delayed significantly
- [ ] Database operations efficient

## Additional Testing Scenarios

### Test with Existing Data
1. Populate database with sample data
2. Run migrations
3. Verify data integrity
4. Confirm new fields are properly handled

### Test with Large Datasets
1. Create large dataset (1000+ records)
2. Run migrations
3. Measure performance impact
4. Verify no data loss

### Test with Network Issues
1. Simulate intermittent connectivity
2. Run migrations
3. Verify error handling
4. Confirm retry mechanisms work

## Conclusion

After completing all these manual tests, you should have verified that:

1. ✅ Database migrations work correctly
2. ✅ All tables and columns are created properly
3. ✅ RLS policies are applied
4. ✅ Application functions normally
5. ✅ Data integrity is maintained
6. ✅ Error handling works appropriately
7. ✅ Performance is acceptable

If all tests pass, your database migration implementation is ready for production use.