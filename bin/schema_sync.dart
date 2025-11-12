import 'dart:io';
import 'package:worker_managment_app/services/schema_manager.dart';
import 'package:worker_managment_app/utils/logger.dart';

Future<void> main(List<String> args) async {
  try {
    Logger.info('Starting Schema Synchronization Tool...');
    
    // Initialize the schema manager
    final schemaManager = SchemaManager();
    
    // Parse command line arguments
    if (args.isEmpty) {
      await _showHelp();
      exit(0);
    }
    
    final command = args[0];
    
    switch (command) {
      case 'sync':
        await _runFullSync(schemaManager);
        break;
      
      case 'add-column':
        if (args.length < 4) {
          Logger.error('Usage: dart schema_sync.dart add-column <table> <column> <type>');
          exit(1);
        }
        await _addColumn(schemaManager, args[1], args[2], args[3]);
        break;
      
      case 'remove-column':
        if (args.length < 3) {
          Logger.error('Usage: dart schema_sync.dart remove-column <table> <column>');
          exit(1);
        }
        await _removeColumn(schemaManager, args[1], args[2]);
        break;
      
      case 'rename-column':
        if (args.length < 4) {
          Logger.error('Usage: dart schema_sync.dart rename-column <table> <old_column> <new_column>');
          exit(1);
        }
        await _renameColumn(schemaManager, args[1], args[2], args[3]);
        break;
      
      case 'status':
        await _showStatus(schemaManager);
        break;
      
      case 'help':
        await _showHelp();
        break;
      
      default:
        Logger.error('Unknown command: $command');
        await _showHelp();
        exit(1);
    }
    
    Logger.info('Schema Synchronization Tool completed successfully');
  } catch (e) {
    Logger.error('Schema Synchronization Tool failed: $e', e);
    exit(1);
  }
}

Future<void> _showHelp() async {
  print('''
Schema Synchronization Tool
==========================

Usage: dart schema_sync.dart <command> [arguments]

Commands:
  sync              Run full schema synchronization
  add-column        Add a new column to a table
  remove-column     Remove a column from a table
  rename-column     Rename a column in a table
  status            Show current schema status
  help              Show this help message

Examples:
  dart schema_sync.dart sync
  dart schema_sync.dart add-column users profile_image text
  dart schema_sync.dart remove-column attendance location_data
  dart schema_sync.dart rename-column users full_name name
''');
}

Future<void> _runFullSync(SchemaManager schemaManager) async {
  Logger.info('Running full schema synchronization...');
  final success = await schemaManager.synchronizeSchema();
  
  if (success) {
    Logger.info('✅ Full schema synchronization completed successfully');
  } else {
    Logger.error('❌ Full schema synchronization failed');
    exit(1);
  }
}

Future<void> _addColumn(SchemaManager schemaManager, String table, String column, String type) async {
  Logger.info('Adding column $column of type $type to table $table...');
  final success = await schemaManager.addColumn(
    tableName: table,
    columnName: column,
    columnType: type,
  );
  
  if (success) {
    Logger.info('✅ Column added successfully');
  } else {
    Logger.error('❌ Failed to add column');
    exit(1);
  }
}

Future<void> _removeColumn(SchemaManager schemaManager, String table, String column) async {
  Logger.info('Removing column $column from table $table...');
  final success = await schemaManager.removeColumn(
    tableName: table,
    columnName: column,
  );
  
  if (success) {
    Logger.info('✅ Column removed successfully');
  } else {
    Logger.error('❌ Failed to remove column');
    exit(1);
  }
}

Future<void> _renameColumn(SchemaManager schemaManager, String table, String oldColumn, String newColumn) async {
  Logger.info('Renaming column $oldColumn to $newColumn in table $table...');
  final success = await schemaManager.renameColumn(
    tableName: table,
    oldColumnName: oldColumn,
    newColumnName: newColumn,
  );
  
  if (success) {
    Logger.info('✅ Column renamed successfully');
  } else {
    Logger.error('❌ Failed to rename column');
    exit(1);
  }
}

Future<void> _showStatus(SchemaManager schemaManager) async {
  Logger.info('Fetching schema status...');
  final status = await schemaManager.getSchemaStatus();
  
  print('''
Schema Status:
  Version: ${status['schema_version']}
  Tables: ${status['tables'].join(', ')}
  Status: ${status['status']}
  Last Sync: ${status['last_sync']}
''');
}