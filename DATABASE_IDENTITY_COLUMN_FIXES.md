# Database Identity Column Fixes

## Overview
This document summarizes the fixes implemented to resolve the "column 'id' can only be updated to DEFAULT" error that was occurring when trying to insert or update records in tables with GENERATED ALWAYS identity columns.

## Issue Identified
The error was occurring because some services were trying to pass explicit ID values when updating records in tables that have GENERATED ALWAYS identity columns. The PostgreSQL database was rejecting these operations with the error:

```
PostgrestException(message: column "id" can only be updated to DEFAULT, code: 428C9, details: Column "id" is an identity column defined as GENERATED ALWAYS., hint: null)
```

## Root Cause
Tables in the database schema were defined with `GENERATED ALWAYS AS IDENTITY` for their primary key columns, which means:
1. The database automatically generates unique values for these columns
2. Explicit values cannot be inserted or updated for these columns
3. Any attempt to pass ID values in INSERT or UPDATE operations would fail

## Tables Affected
All tables in the database schema have GENERATED ALWAYS identity columns:
- `users` table (id column)
- `attendance` table (id column)
- `advance` table (id column)
- `salary` table (id column)
- `login_status` table (id column)
- `notifications` table (id column)
- `admin_user_mapping` table (id column)

## Fix Implemented

### 1. Users Service
**File**: [lib/services/users_service.dart](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\users_service.dart)

**Issue**: The [updateUser](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\users_service.dart#L56-L65) method was not removing the 'id' field from the payload before updating.

**Fix Applied**:
```dart
Future<void> updateUser(int id, Map<String, dynamic> data) async {
  final payload = MapCase.toSnake(data);
  // For GENERATED ALWAYS identity columns, never pass an ID value
  // Remove ID for update operations
  if (payload.containsKey('id')) {
    payload.remove('id');
  }
  
  try {
    await supa.from('users').update(payload).eq('id', id);
  } catch (e) {
    await _schemaRefresher.tryFixExtendedSchemaError(e);
    await Future.delayed(const Duration(seconds: 2));
    await supa.from('users').update(payload).eq('id', id);
  }
}
```

### 2. Service Consistency Check
Verified that all other services were already correctly handling ID removal:
- **Attendance Service**: [updateById](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\attendance_service.dart#L234-L253) method correctly removes ID
- **Advance Service**: [updateById](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\advance_service.dart#L63-L82) method correctly removes ID
- **Salary Service**: [updateById](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\salary_service.dart#L108-L127) method correctly removes ID
- **Login Service**: [upsertStatus](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\login_service.dart#L9-L33) and [insertHistory](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\login_service.dart#L120-L137) methods correctly remove ID
- **Notifications Service**: [insert](file://c:\Users\Admin\Desktop\Project\worker_management_app\lib\services\notifications_service.dart#L11-L32) method correctly removes ID

## Technical Details

### Data Flow
1. Application creates data models with ID fields (which may have values)
2. Services convert models to maps using `MapCase.toSnake()`
3. Services remove ID fields from payloads before database operations
4. Database automatically generates new ID values for INSERT operations
5. UPDATE operations target records by ID without passing the ID in the payload

### Error Prevention
All services now follow the same pattern:
1. Convert data to snake_case using `MapCase.toSnake()`
2. Remove 'id' field from payload if present
3. Perform database operation with proper error handling
4. Include schema refresh retry logic for robustness

## Verification

The fix has been implemented and verified:
- ✅ Users service now correctly removes ID from update payloads
- ✅ All other services already had proper ID handling
- ✅ Database operations no longer fail with identity column errors
- ✅ Schema refresh retry logic maintains application robustness
- ✅ Data integrity is preserved with auto-generated IDs

## Impact

These fixes resolve the database identity column issues by:
1. Ensuring no explicit ID values are passed to GENERATED ALWAYS identity columns
2. Maintaining consistency across all database services
3. Preventing future occurrences of similar errors
4. Preserving the intended database schema behavior

The application can now successfully perform insert and update operations on all tables without encountering the "column 'id' can only be updated to DEFAULT" error.