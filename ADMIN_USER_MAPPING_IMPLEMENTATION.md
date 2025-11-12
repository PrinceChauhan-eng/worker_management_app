# Admin-User Mapping System Implementation

## 🎯 Overview

This document describes the implementation of an admin-user mapping system in the Flutter + Supabase Worker Management App. The system ensures that each admin can only manage workers they have created, with full security enforcement at both the database and application levels.

## 🧩 Components Implemented

### 1. Database Schema Changes

#### Users Table Updates
- Added `created_by` column (UUID) referencing `auth.users(id)`
- Added index on `created_by` for performance
- Updated RLS policies to enforce admin-user mapping

#### New Admin-User Mapping Table
```sql
create table if not exists public.admin_user_mapping (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users(id) on delete cascade,
  user_id bigint references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique (admin_id, user_id)
);
```

### 2. Row Level Security (RLS) Policies

#### Users Table Policies
- **Select**: Admins can only view workers mapped to them
- **Insert**: Only admins can create workers
- **Update**: Admins can only update their own workers
- **Delete**: Admins can only delete their own workers

#### Admin-User Mapping Table Policies
- **Select**: Admins can only view their own mappings
- **Insert**: Admins can only create mappings for themselves
- **Delete**: Admins can only delete their own mappings

### 3. Automatic Mapping Function

```sql
create or replace function public.auto_map_admin_to_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by is not null then
    insert into public.admin_user_mapping (admin_id, user_id)
    values (new.created_by, new.id)
    on conflict do nothing;
  end if;
  return new;
end;
$$;
```

### 4. Flutter Model Updates

#### User Model
- Added `createdBy` field to track which admin created the user
- Updated `toMap()` and `fromMap()` methods
- Updated `copyWith()` method
- Updated profile completion percentage calculation

### 5. Service Layer Implementation

#### UserService Updates
- Automatically sets `created_by` to current admin when creating users
- Added `getWorkersForCurrentAdmin()` method
- Added `doesCurrentAdminHaveAccessToUser()` method

#### New AdminUserMappingService
- `createMapping()` - Create admin-user mapping
- `getMappings()` - Get all mappings for current admin
- `getMappingsForAdmin()` - Get mappings for specific admin
- `getMappingsForUser()` - Get mappings for specific user
- `deleteMapping()` - Delete specific mapping
- `deleteMappingByAdminAndUser()` - Delete mapping between specific admin and user
- `isAdminMappedToUser()` - Check if admin has access to user
- `getUsersForAdmin()` - Get all users mapped to admin
- `autoMapAdminToUser()` - Automatically map admin to user

## 🔐 Security Features

### Database Level Security
1. **Row Level Security**: Enforced by Supabase RLS policies
2. **Automatic Mapping**: Trigger ensures mapping is created when user is inserted
3. **Unique Constraints**: Prevents duplicate mappings
4. **Foreign Key Constraints**: Ensures data integrity
5. **Indexing**: Optimized for performance

### Application Level Security
1. **Automatic createdBy Setting**: UserService automatically sets created_by
2. **Access Control**: Methods to check admin access to users
3. **Filtered Queries**: Only returns users mapped to current admin
4. **Error Handling**: Graceful handling of permission errors

## 🚀 Usage Examples

### Creating a Worker (Admin)
```dart
// UserService automatically sets created_by
final userId = await userService.insertUser({
  'name': 'John Worker',
  'phone': '+1234567890',
  'password': 'securepassword',
  'role': 'worker',
  'wage': 15.0,
  'joinDate': '2025-01-01',
  // created_by is automatically set to current admin
});
```

### Fetching Workers (Admin)
```dart
// Returns only workers mapped to current admin
final workers = await userService.getWorkersForCurrentAdmin();
```

### Checking Access
```dart
// Check if current admin has access to a user
final hasAccess = await userService.doesCurrentAdminHaveAccessToUser(userId);
```

### Admin-User Mapping Service
```dart
final mappingService = AdminUserMappingService();

// Create mapping
await mappingService.createMapping(adminId, userId);

// Check if admin has access to user
final hasAccess = await mappingService.isAdminMappedToUser(adminId, userId);

// Get all users for admin
final users = await mappingService.getUsersForAdmin(adminId);
```

## 🧪 Verification Tests

| Action | Expected Result |
|--------|----------------|
| Admin A adds Worker 1 | ✅ Auto maps in admin_user_mapping |
| Admin B tries to view Worker 1 | ❌ Returns nothing |
| Admin A updates Worker 1 | ✅ Works |
| Admin B deletes Worker 1 | ❌ Permission denied |
| Super Admin fetches all users | ✅ Works (if policy enabled) |

## 📁 Files Modified/Added

1. `database/schema.sql` - Updated with new table and policies
2. `database/tables/users.sql` - Updated users table schema
3. `database/tables/admin_user_mapping.sql` - New mapping table
4. `lib/models/user.dart` - Added createdBy field
5. `lib/services/users_service.dart` - Updated with mapping logic
6. `lib/services/admin_user_mapping_service.dart` - New service
7. `lib/services/database_updater.dart` - Updated with new table and policies

## 🛡️ Error Handling

The system includes robust error handling:
- Schema refresher integration for database errors
- Permission error handling for RLS violations
- Retry logic for transient failures
- Comprehensive logging for debugging

## 🎯 Benefits

1. **Data Isolation**: Admins can only access their own workers
2. **Automatic Mapping**: No manual mapping required
3. **Security Enforcement**: Both database and application level security
4. **Performance Optimized**: Indexes and efficient queries
5. **Extensible**: Easy to add super admin functionality
6. **Audit Trail**: Created_by field tracks admin actions

## 🔄 Future Enhancements

1. **Super Admin Override**: Full access to all users
2. **Mapping Transfers**: Transfer workers between admins
3. **Bulk Operations**: Batch mapping operations
4. **Audit Logging**: Track all mapping changes
5. **Notification System**: Alert on mapping changes