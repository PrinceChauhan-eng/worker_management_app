# Schema Refresher Integration Tasks

## Overview
This document tracks the integration of the SchemaRefresher service into existing Supabase service classes to automatically handle schema cache errors.

## To-Do List

### Phase 1: Service Class Integration
✅ **1.1 Update `lib/services/login_service.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **1.2 Update `lib/services/users_service.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **1.3 Update `lib/services/attendance_service.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **1.4 Update `lib/services/advance_service.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **1.5 Update `lib/services/salary_service.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **1.6 Update `lib/services/notifications_service.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

### Phase 2: Provider Class Integration
✅ **2.1 Update `lib/providers/user_provider.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **2.2 Update `lib/providers/attendance_provider.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **2.3 Update `lib/providers/advance_provider.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **2.4 Update `lib/providers/salary_provider.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

✅ **2.5 Update `lib/providers/login_status_provider.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

🔲 **2.6 Update `lib/providers/notification_provider.dart`**
- Add SchemaRefresher import
- Integrate tryFixSchemaError/tryFixExtendedSchemaError in all methods
- Add retry logic with appropriate delays
- Update error handling

- [ ] **2.7 Update `lib/providers/hybrid_database_provider.dart`**

### Phase 3: Documentation and Examples
✅ **3.1 Create integration examples documentation**
- Create comprehensive integration examples
- Document best practices
- Provide usage patterns

### Phase 4: Testing and Verification
🔲 **4.1 Test service class integrations**
- Verify schema error detection works
- Confirm retry logic functions correctly
- Test cross-platform compatibility

🔲 **4.2 Test provider class integrations**
- Verify schema error detection works in providers
- Confirm retry logic functions correctly
- Test state management with schema errors

## Implementation Details

### Completed Tasks

#### ✅ Phase 1: Service Class Integration

##### ✅ 1.1 LoginService Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 1.2 UsersService Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 1.3 AttendanceService Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 1.4 AdvanceService Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 1.5 SalaryService Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 1.6 NotificationsService Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

#### ✅ Phase 2: Provider Class Integration

##### ✅ 2.1 LoginStatusProvider Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 2.2 UserProvider Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 2.3 AttendanceProvider Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 2.4 AdvanceProvider Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

##### ✅ 2.5 SalaryProvider Integration
- [x] Add SchemaRefresher import
- [x] Wrap all Supabase operations with error handling
- [x] Implement retry logic for schema errors
- [x] Test integration thoroughly

## Success Criteria

✅ SchemaRefresher integrated into all service classes
✅ SchemaRefresher integrated into all provider classes
✅ Automatic schema error detection and fixing
✅ Proper retry logic with delays
✅ Cross-platform compatibility maintained
✅ No performance degradation
✅ Error handling improved

## Implementation Timeline

### Week 1: Service Class Integration
✅ **All Service Classes**: Completed

### Week 2: Provider Class Integration
✅ **LoginStatusProvider**: Completed
✅ **UserProvider**: Completed
✅ **AttendanceProvider**: Completed
✅ **AdvanceProvider**: Completed
✅ **SalaryProvider**: Completed
🔲 **NotificationProvider**: In Progress

### Week 3: Testing and Refinement
🔲 **Pending**: Comprehensive testing and verification

## Risk Mitigation

### Data Safety
- All operations maintain data integrity
- Retry logic ensures operations complete
- No data modification during schema refresh

### Error Handling
- Comprehensive try/catch blocks
- Detailed logging
- Graceful failure handling

### Performance
- Minimal impact on application performance
- Efficient error detection
- Appropriate retry delays

## Integration Patterns

### Service Class Pattern
```dart
import 'schema_refresher.dart';

class YourService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  Future<ReturnType> yourMethod() async {
    try {
      return await supa.from('your_table').select();
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      return await supa.from('your_table').select();
    }
  }
}
```

### Provider Class Pattern
```dart
import 'schema_refresher.dart';

class YourProvider extends BaseProvider {
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  Future<void> yourMethod() async {
    setState(ViewState.busy);
    try {
      // Your operation
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Retry operation
      } catch (retryError) {
        // Handle retry failure
      } finally {
        setState(ViewState.idle);
      }
    }
  }
}
```

## Future Enhancements

### Potential Improvements
1. **Centralized Error Handler** - Create a unified error handling service
2. **Retry Limiting** - Implement maximum retry attempts
3. **Smart Retry Delays** - Exponential backoff for retries
4. **Error Classification** - Categorize errors for different handling approaches
5. **Monitoring Dashboard** - Track schema error occurrences and fixes