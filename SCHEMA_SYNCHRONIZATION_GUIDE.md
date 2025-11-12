# Schema Synchronization Guide

## Overview

This guide explains how to use the Schema Synchronization system to keep your Flutter + Supabase Worker Management App fully synchronized whenever you add, remove, or modify table columns or structure.

## 🎯 Key Features

- **Automatic Model Updates**: When you modify the database schema, the corresponding Dart models are automatically updated
- **Service Synchronization**: All service classes (CRUD operations) are kept in sync with the database schema
- **SQL Schema Generation**: Complete SQL schema files are automatically generated and maintained
- **Error Prevention**: Automatic detection and fixing of schema cache issues
- **Validation Testing**: Comprehensive testing to ensure all features work after schema changes
- **Migration Tracking**: Complete history of all schema changes

## 📁 File Structure

```
database/
├── schema.sql                 # Complete database schema
├── tables/
│   ├── users.sql             # Users table schema
│   ├── attendance.sql        # Attendance table schema
│   ├── login_status.sql      # Login status table schema
│   ├── advance.sql           # Advance table schema
│   ├── salary.sql            # Salary table schema
│   └── notifications.sql     # Notifications table schema
└── migrations/
    └── changes.log           # Schema change history

lib/
├── services/
│   ├── schema_manager.dart          # Main schema management service
│   ├── schema_sync_service.dart     # Schema synchronization service
│   ├── model_updater_service.dart   # Model updater service
│   ├── service_updater_service.dart # Service updater service
│   ├── schema_validation_service.dart # Validation service
│   └── schema_refresher.dart        # Schema cache refresh service
└── models/
    ├── user.dart               # User model
    ├── attendance.dart         # Attendance model
    ├── login_status.dart       # Login status model
    ├── advance.dart            # Advance model
    ├── salary.dart             # Salary model
    └── notification.dart       # Notification model
```

## 🚀 Usage

### 1. Full Schema Synchronization

To run a complete schema synchronization:

```bash
dart bin/schema_sync.dart sync
```

This will:
- Validate the current schema
- Update all model files
- Update all service files
- Synchronize the database schema
- Generate reports
- Run validation tests

### 2. Adding a Column

To add a new column to a table:

```bash
dart bin/schema_sync.dart add-column <table_name> <column_name> <column_type>
```

Example:
```bash
dart bin/schema_sync.dart add-column users profile_image text
```

This will:
- Add the column to the database table
- Update the corresponding Dart model
- Update the corresponding service class
- Update the SQL schema files
- Log the change in the migration history

### 3. Removing a Column

To remove a column from a table:

```bash
dart bin/schema_sync.dart remove-column <table_name> <column_name>
```

Example:
```bash
dart bin/schema_sync.dart remove-column attendance location_data
```

This will:
- Remove the column from the database table
- Update the corresponding Dart model
- Update the corresponding service class
- Update the SQL schema files
- Log the change in the migration history

### 4. Renaming a Column

To rename a column in a table:

```bash
dart bin/schema_sync.dart rename-column <table_name> <old_column_name> <new_column_name>
```

Example:
```bash
dart bin/schema_sync.dart rename-column users full_name name
```

This will:
- Rename the column in the database table
- Update the corresponding Dart model
- Update the corresponding service class
- Update the SQL schema files
- Log the change in the migration history

### 5. Checking Schema Status

To check the current schema status:

```bash
dart bin/schema_sync.dart status
```

## 🧪 Validation Testing

The system includes comprehensive validation testing:

### Table Structure Validation
- Verifies all required tables exist
- Checks table accessibility
- Ensures proper column types

### CRUD Operations Validation
- Tests INSERT operations
- Tests SELECT operations
- Tests UPDATE operations
- Tests DELETE operations

### RLS Policies Validation
- Verifies Row Level Security policies are in place
- Checks policy permissions
- Ensures proper access control

### Functions Validation
- Tests required database functions
- Verifies function signatures
- Checks function accessibility

## 🔧 Error Handling

### Schema Cache Issues
The system automatically detects and fixes schema cache issues:
- PGRST204 errors
- "column not in schema cache" errors
- Missing column errors

### Retry Logic
All operations include retry logic with exponential backoff:
- First attempt: Immediate
- Second attempt: After 2 seconds
- Third attempt: After 5 seconds

### Logging
Comprehensive logging for debugging:
- Info level: Normal operations
- Warning level: Non-critical issues
- Error level: Critical failures

## 📊 Reports

The system generates detailed reports:
- Model update reports
- Service update reports
- Schema migration reports
- Validation test reports

## 🔄 Continuous Integration

To integrate with your CI/CD pipeline:

1. Run schema validation before deployment:
```bash
dart bin/schema_sync.dart sync
```

2. Check validation results:
```bash
dart bin/schema_sync.dart status
```

3. Generate reports for audit:
```bash
# Reports are automatically generated during sync
```

## 🛡️ Best Practices

### 1. Always Run Validation
Before making schema changes, always run validation:
```bash
dart bin/schema_sync.dart sync
```

### 2. Backup Before Major Changes
Always backup your database before major schema changes.

### 3. Test in Development
Test all schema changes in development before applying to production.

### 4. Monitor Logs
Monitor the logs for any warnings or errors during synchronization.

### 5. Review Migration History
Regularly review the migration history file for audit purposes.

## 🆘 Troubleshooting

### Common Issues

1. **Schema Cache Errors**
   - Run `dart bin/schema_sync.dart sync` to refresh the schema cache
   - Check Supabase logs for detailed error information

2. **Permission Denied**
   - Ensure your Supabase service role has proper permissions
   - Check RLS policies for the affected tables

3. **Connection Issues**
   - Verify your Supabase connection settings
   - Check network connectivity

4. **Migration Failures**
   - Check the migration log for specific error details
   - Manually resolve conflicts if necessary

### Getting Help

If you encounter issues:
1. Check the logs in the console output
2. Review the migration history file
3. Verify your Supabase configuration
4. Contact support with the error details

## 📈 Monitoring

The system provides monitoring capabilities:
- Real-time status updates
- Performance metrics
- Error tracking
- Audit trails

## 🔄 Future Enhancements

Planned enhancements:
- Automated rollback capabilities
- Advanced migration scripting
- Performance optimization suggestions
- Security compliance checking
- Integration with popular CI/CD platforms

## 📞 Support

For issues or questions, please:
1. Check the documentation
2. Review the logs
3. Contact the development team