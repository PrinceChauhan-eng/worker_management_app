# Database Migration Plan

## Objective
Implement automatic database schema updates and RLS policies for all required tables without dropping existing data.

## To-Do List

### Phase 1: Create Database Updater Service
✅ **1.1 Create `lib/services/database_updater.dart`**
- Implement `DatabaseUpdater` class
- Add migration methods for all tables
- Include error handling and logging
- Add RLS policy application

### Phase 2: Integrate Database Updater
✅ **2.1 Update `main.dart` to run migrations on app start**
- Import database updater service
- Call `runMigrations()` during initialization
- Add proper error handling

### Phase 3: Update Model Classes
✅ **3.1 Update `lib/models/user.dart`**
- Add new fields: work_location_latitude, work_location_longitude, work_location_address, location_radius, profile_photo, id_proof, email_verified, email_verification_code, designation
- Update toMap/fromMap methods

✅ **3.2 Update `lib/models/attendance.dart`**
- Ensure all fields match database schema
- Update toMap/fromMap methods

✅ **3.3 Update `lib/models/login_status.dart`**
- Add new location fields: city, state, pincode, country, logout_city, logout_state, logout_pincode
- Update toMap/fromMap methods

✅ **3.4 Update `lib/models/advance.dart`**
- Ensure all fields match database schema
- Update toMap/fromMap methods

✅ **3.5 Update `lib/models/salary.dart`**
- Ensure all fields match database schema
- Update toMap/fromMap methods

✅ **3.6 Update `lib/models/notification.dart`**
- Ensure all fields match database schema
- Update toMap/fromMap methods

### Phase 4: Update Service Classes
✅ **4.1 Update `lib/services/users_service.dart`**
- Handle new user fields in queries
- Update insert/update methods

✅ **4.2 Update `lib/services/attendance_service.dart`**
- Ensure compatibility with attendance table schema
- Update insert/update methods

✅ **4.3 Update `lib/services/login_service.dart`**
- Handle new login status fields in queries
- Update insert/update methods

✅ **4.4 Update `lib/services/advance_service.dart`**
- Ensure compatibility with advance table schema
- Update insert/update methods

✅ **4.5 Update `lib/services/salary_service.dart`**
- Ensure compatibility with salary table schema
- Update insert/update methods

✅ **4.6 Update `lib/services/notifications_service.dart`**
- Ensure compatibility with notifications table schema
- Update insert/update methods

### Phase 5: Update Provider Classes
✅ **5.1 Update `lib/providers/user_provider.dart`**
- Handle new user fields
- Update provider methods

✅ **5.2 Update `lib/providers/attendance_provider.dart`**
- Ensure compatibility with updated attendance model
- Update provider methods

✅ **5.3 Update `lib/providers/login_status_provider.dart`**
- Handle new login status fields
- Update provider methods

✅ **5.4 Update `lib/providers/advance_provider.dart`**
- Ensure compatibility with updated advance model
- Update provider methods

✅ **5.5 Update `lib/providers/salary_provider.dart`**
- Ensure compatibility with updated salary model
- Update provider methods

✅ **5.6 Update `lib/providers/notification_provider.dart`**
- Ensure compatibility with updated notification model
- Update provider methods

### Phase 6: Testing and Verification
✅ **6.1 Test Database Migrations**
- Verify all tables are created/updated correctly
- Confirm no data loss
- Test RLS policies work correctly

🔲 **6.2 Test Application Functionality**
- Verify all CRUD operations work
- Test location tracking features
- Confirm web and mobile compatibility

🔲 **6.3 Performance Testing**
- Ensure migrations run efficiently
- Verify no performance degradation
- Test with large datasets

## Implementation Timeline

### Day 1: Core Infrastructure
✅ **Completed**: DatabaseUpdater service, main.dart integration, all model updates

### Day 2: Service and Provider Updates
✅ **Completed**: All service and provider class updates

### Day 3: Testing and Refinement
🔲 **In Progress**: Comprehensive testing and verification

## Risk Mitigation

### Data Safety
- All migrations use `if not exists` clauses
- No DROP TABLE statements
- Backward compatibility maintained

### Error Handling
- Comprehensive try/catch blocks
- Detailed logging
- Graceful failure handling

### Performance
- Efficient SQL queries
- Minimal database round trips
- Async operations

## Success Criteria

✅ All tables exist with correct schema
✅ All required columns added without data loss
✅ RLS policies applied correctly
✅ Application functions normally on web and mobile
✅ No existing data corrupted or lost
✅ Migration process runs automatically on app start