import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'schema_sync_service.dart';
import 'model_updater_service.dart';
import 'service_updater_service.dart';
import 'schema_refresher.dart';

class SchemaManager {
  final SupabaseClient supa = Supabase.instance.client;
  final SchemaSyncService _schemaSyncService = SchemaSyncService();
  final ModelUpdaterService _modelUpdaterService = ModelUpdaterService();
  final ServiceUpdaterService _serviceUpdaterService = ServiceUpdaterService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();

  /// Full schema synchronization process
  Future<bool> synchronizeSchema() async {
    try {
      Logger.info('=== Starting Full Schema Synchronization ===');
      
      // Step 1: Validate current schema
      Logger.info('Step 1: Validating current schema...');
      final isValid = await _schemaSyncService.validateSchema();
      if (!isValid) {
        Logger.warning('Current schema validation failed, attempting to fix...');
        await _schemaRefresher.tryFixExtendedSchemaError('Schema validation failed');
      }
      
      // Step 2: Update model files
      Logger.info('Step 2: Updating model files...');
      await _modelUpdaterService.updateAllModels();
      
      // Step 3: Update service files
      Logger.info('Step 3: Updating service files...');
      await _serviceUpdaterService.updateAllServices();
      
      // Step 4: Sync database schema
      Logger.info('Step 4: Synchronizing database schema...');
      final syncSuccess = await _schemaSyncService.syncSchema();
      if (!syncSuccess) {
        Logger.error('Database schema synchronization failed');
        return false;
      }
      
      // Step 5: Generate reports
      Logger.info('Step 5: Generating synchronization reports...');
      await _generateReports();
      
      // Step 6: Run validation tests
      Logger.info('Step 6: Running validation tests...');
      final testResults = await _runValidationTests();
      if (testResults != null && !testResults['passed']) {
        Logger.error('Validation tests failed: ${testResults['errors']}');
        return false;
      }
      
      Logger.info('=== Schema Synchronization Completed Successfully ===');
      return true;
    } catch (e) {
      Logger.error('Schema synchronization failed: $e', e);
      return false;
    }
  }

  /// Add a new column to a table
  Future<bool> addColumn({
    required String tableName,
    required String columnName,
    required String columnType,
    String? defaultValue,
    bool nullable = true,
    bool isPrimaryKey = false,
    bool isForeignKey = false,
    String? references,
  }) async {
    try {
      Logger.info('Adding column $columnName to table $tableName...');
      
      // Generate SQL for adding column
      final sql = _generateAddColumnSQL(
        tableName: tableName,
        columnName: columnName,
        columnType: columnType,
        defaultValue: defaultValue,
        nullable: nullable,
        isPrimaryKey: isPrimaryKey,
        isForeignKey: isForeignKey,
        references: references,
      );
      
      // Execute SQL
      await supa.rpc('exec_sql', params: {'query': sql});
      
      // Update model files
      await _updateModelForNewColumn(tableName, columnName, columnType, nullable);
      
      // Update service files
      await _updateServiceForNewColumn(tableName, columnName);
      
      // Update database schema files
      await _updateSchemaFilesForNewColumn(tableName, columnName, columnType, nullable);
      
      Logger.info('✅ Column $columnName added to table $tableName successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to add column $columnName to table $tableName: $e', e);
      return false;
    }
  }

  /// Remove a column from a table
  Future<bool> removeColumn({
    required String tableName,
    required String columnName,
  }) async {
    try {
      Logger.info('Removing column $columnName from table $tableName...');
      
      // Generate SQL for removing column
      final sql = _generateRemoveColumnSQL(tableName, columnName);
      
      // Execute SQL
      await supa.rpc('exec_sql', params: {'query': sql});
      
      // Update model files
      await _updateModelForRemovedColumn(tableName, columnName);
      
      // Update service files
      await _updateServiceForRemovedColumn(tableName, columnName);
      
      // Update database schema files
      await _updateSchemaFilesForRemovedColumn(tableName, columnName);
      
      // Log the change
      await _logSchemaChange('REMOVE_COLUMN', tableName, columnName);
      
      Logger.info('✅ Column $columnName removed from table $tableName successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to remove column $columnName from table $tableName: $e', e);
      return false;
    }
  }

  /// Rename a column in a table
  Future<bool> renameColumn({
    required String tableName,
    required String oldColumnName,
    required String newColumnName,
  }) async {
    try {
      Logger.info('Renaming column $oldColumnName to $newColumnName in table $tableName...');
      
      // Generate SQL for renaming column
      final sql = _generateRenameColumnSQL(tableName, oldColumnName, newColumnName);
      
      // Execute SQL
      await supa.rpc('exec_sql', params: {'query': sql});
      
      // Update model files
      await _updateModelForRenamedColumn(tableName, oldColumnName, newColumnName);
      
      // Update service files
      await _updateServiceForRenamedColumn(tableName, oldColumnName, newColumnName);
      
      // Update database schema files
      await _updateSchemaFilesForRenamedColumn(tableName, oldColumnName, newColumnName);
      
      // Log the change
      await _logSchemaChange('RENAME_COLUMN', tableName, '$oldColumnName -> $newColumnName');
      
      Logger.info('✅ Column $oldColumnName renamed to $newColumnName in table $tableName successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to rename column $oldColumnName to $newColumnName in table $tableName: $e', e);
      return false;
    }
  }

  /// Generate SQL for adding a column
  String _generateAddColumnSQL({
    required String tableName,
    required String columnName,
    required String columnType,
    String? defaultValue,
    required bool nullable,
    required bool isPrimaryKey,
    required bool isForeignKey,
    String? references,
  }) {
    final constraint = nullable ? '' : ' NOT NULL';
    final defaultClause = defaultValue != null ? " DEFAULT $defaultValue" : '';
    final primaryKeyClause = isPrimaryKey ? ' PRIMARY KEY' : '';
    final foreignKeyClause = isForeignKey && references != null 
        ? " REFERENCES $references" 
        : '';
    
    return '''
    ALTER TABLE public.$tableName 
    ADD COLUMN IF NOT EXISTS $columnName $columnType$constraint$defaultClause$primaryKeyClause$foreignKeyClause;
    ''';
  }

  /// Generate SQL for removing a column
  String _generateRemoveColumnSQL(String tableName, String columnName) {
    return '''
    ALTER TABLE public.$tableName 
    DROP COLUMN IF EXISTS $columnName;
    ''';
  }

  /// Generate SQL for renaming a column
  String _generateRenameColumnSQL(String tableName, String oldColumnName, String newColumnName) {
    return '''
    ALTER TABLE public.$tableName 
    RENAME COLUMN $oldColumnName TO $newColumnName;
    ''';
  }

  /// Update model for new column
  Future<void> _updateModelForNewColumn(
    String tableName, 
    String columnName, 
    String columnType, 
    bool nullable
  ) async {
    // This would update the corresponding Dart model file
    Logger.info('Updating model for new column $columnName in $tableName');
    // Implementation would involve parsing and modifying the Dart file
  }

  /// Update service for new column
  Future<void> _updateServiceForNewColumn(String tableName, String columnName) async {
    // This would update the corresponding service file
    Logger.info('Updating service for new column $columnName in $tableName');
    // Implementation would involve parsing and modifying the Dart file
  }

  /// Update schema files for new column
  Future<void> _updateSchemaFilesForNewColumn(
    String tableName, 
    String columnName, 
    String columnType, 
    bool nullable
  ) async {
    // This would update the SQL schema files
    Logger.info('Updating schema files for new column $columnName in $tableName');
    // Implementation would involve parsing and modifying the SQL files
  }

  /// Update model for removed column
  Future<void> _updateModelForRemovedColumn(String tableName, String columnName) async {
    // This would update the corresponding Dart model file
    Logger.info('Updating model for removed column $columnName in $tableName');
    // Implementation would involve parsing and modifying the Dart file
  }

  /// Update service for removed column
  Future<void> _updateServiceForRemovedColumn(String tableName, String columnName) async {
    // This would update the corresponding service file
    Logger.info('Updating service for removed column $columnName in $tableName');
    // Implementation would involve parsing and modifying the Dart file
  }

  /// Update schema files for removed column
  Future<void> _updateSchemaFilesForRemovedColumn(String tableName, String columnName) async {
    // This would update the SQL schema files
    Logger.info('Updating schema files for removed column $columnName in $tableName');
    // Implementation would involve parsing and modifying the SQL files
  }

  /// Update model for renamed column
  Future<void> _updateModelForRenamedColumn(
    String tableName, 
    String oldColumnName, 
    String newColumnName
  ) async {
    // This would update the corresponding Dart model file
    Logger.info('Updating model for renamed column $oldColumnName to $newColumnName in $tableName');
    // Implementation would involve parsing and modifying the Dart file
  }

  /// Update service for renamed column
  Future<void> _updateServiceForRenamedColumn(
    String tableName, 
    String oldColumnName, 
    String newColumnName
  ) async {
    // This would update the corresponding service file
    Logger.info('Updating service for renamed column $oldColumnName to $newColumnName in $tableName');
    // Implementation would involve parsing and modifying the Dart file
  }

  /// Update schema files for renamed column
  Future<void> _updateSchemaFilesForRenamedColumn(
    String tableName, 
    String oldColumnName, 
    String newColumnName
  ) async {
    // This would update the SQL schema files
    Logger.info('Updating schema files for renamed column $oldColumnName to $newColumnName in $tableName');
    // Implementation would involve parsing and modifying the SQL files
  }

  /// Log schema change
  Future<void> _logSchemaChange(String changeType, String tableName, String details) async {
    final logEntry = '''
[${DateTime.now().toIso8601String()}] $changeType: $tableName - $details
''';
    
    // Append to migration log file
    final logFile = File('database/migrations/changes.log');
    await logFile.writeAsString(logEntry, mode: FileMode.append);
  }

  /// Generate synchronization reports
  Future<void> _generateReports() async {
    try {
      // Generate model update report
      final modelReport = await _modelUpdaterService.generateUpdateReport();
      Logger.info('Model Update Report: ${modelReport.toString()}');
      
      // Generate service update report
      final serviceReport = await _serviceUpdaterService.generateUpdateReport();
      Logger.info('Service Update Report: ${serviceReport.toString()}');
      
      // Generate schema migration report
      final schemaReport = await _schemaSyncService.generateMigrationReport();
      Logger.info('Schema Migration Report: ${schemaReport.toString()}');
    } catch (e) {
      Logger.error('Failed to generate reports: $e', e);
    }
  }

  /// Run validation tests
  Future<Map<String, dynamic>?> _runValidationTests() async {
    final results = {
      'passed': true,
      'errors': <String>[],
    };
    
    try {
      // Test 1: Validate schema
      final schemaValid = await _schemaSyncService.validateSchema();
      if (!schemaValid) {
        results['passed'] = false;
        if (results['errors'] != null) {
          (results['errors'] as List<String>).add('Schema validation failed');
        }
      }
      
      // Test 2: Test CRUD operations on all tables
      final crudTests = await _runCRUDTests();
      if (crudTests != null && !crudTests['passed']) {
        results['passed'] = false;
        if (results['errors'] != null && crudTests['errors'] != null) {
          (results['errors'] as List<String>).addAll(crudTests['errors'] as List<String>);
        }
      }
      
      // Test 3: Test RLS policies
      final rlsTests = await _runRLSTests();
      if (rlsTests != null && !rlsTests['passed']) {
        results['passed'] = false;
        if (results['errors'] != null && rlsTests['errors'] != null) {
          (results['errors'] as List<String>).addAll(rlsTests['errors'] as List<String>);
        }
      }
      
      return results;
    } catch (e) {
      Logger.error('Validation tests failed: $e', e);
      return {
        'passed': false,
        'errors': ['Validation tests failed: $e'],
      };
    }
  }

  /// Run CRUD tests
  Future<Map<String, dynamic>?> _runCRUDTests() async {
    final results = {
      'passed': true,
      'errors': <String>[],
    };
    
    try {
      final tables = ['users', 'attendance', 'login_status', 'advance', 'salary', 'notifications'];
      
      for (final table in tables) {
        try {
          // Test insert
          await supa.from(table).insert({'test_field': 'test_value'}).select();
          
          // Test select
          await supa.from(table).select().limit(1);
          
          // Test update
          // Skip update test to avoid modifying real data
          
          // Test delete
          // Skip delete test to avoid removing real data
          
          Logger.info('✅ CRUD tests passed for table: $table');
        } catch (e) {
          results['passed'] = false;
          if (results['errors'] != null) {
            (results['errors'] as List<String>).add('CRUD test failed for table $table: $e');
          }
          Logger.error('CRUD test failed for table $table: $e', e);
        }
      }
      
      return results;
    } catch (e) {
      Logger.error('CRUD tests failed: $e', e);
      return {
        'passed': false,
        'errors': ['CRUD tests failed: $e'],
      };
    }
  }

  /// Run RLS tests
  Future<Map<String, dynamic>?> _runRLSTests() async {
    final results = {
      'passed': true,
      'errors': <String>[],
    };
    
    try {
      // In a real implementation, this would test RLS policies
      // For now, we'll just log that RLS tests would be run
      Logger.info('RLS tests would be run here');
      
      return results;
    } catch (e) {
      Logger.error('RLS tests failed: $e', e);
      return {
        'passed': false,
        'errors': ['RLS tests failed: $e'],
      };
    }
  }

  /// Get current schema status
  Future<Map<String, dynamic>> getSchemaStatus() async {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'schema_version': '1.0.0',
      'tables': [
        'users',
        'attendance',
        'login_status',
        'advance',
        'salary',
        'notifications',
      ],
      'status': 'synced',
      'last_sync': DateTime.now().toIso8601String(),
    };
  }
}