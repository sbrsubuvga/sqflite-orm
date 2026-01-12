import 'package:sqflite_common/sqlite_api.dart' show Database;
import 'package:sqflite_orm/src/models/model_registry.dart';

/// Manages database migrations
class MigrationManager {
  /// Create all tables for registered models
  Future<void> createTables(Database db, List<Type> models) async {
    for (final modelType in models) {
      final info = ModelRegistry().getInfo(modelType);
      if (info == null) {
        print(
            'Warning: Model $modelType not registered, skipping table creation');
        continue;
      }

      await _createTable(db, info);
    }
  }

  /// Create a table for a model
  ///
  /// Uses CREATE TABLE IF NOT EXISTS (sqflite best practice)
  /// This is safe to call multiple times
  Future<void> _createTable(Database db, ModelInfo info) async {
    if (info.columns.isEmpty) {
      throw ArgumentError(
          'Cannot create table ${info.tableName} with no columns');
    }

    final buffer = StringBuffer();
    buffer.write('CREATE TABLE IF NOT EXISTS ${info.tableName} (');

    final columns = <String>[];
    for (final entry in info.columns.entries) {
      final columnName = entry.key;
      final columnInfo = entry.value;
      final columnDef = _buildColumnDefinition(columnName, columnInfo);
      columns.add(columnDef);
    }

    if (columns.isEmpty) {
      throw ArgumentError(
          'Cannot create table ${info.tableName} - no valid column definitions');
    }

    buffer.write(columns.join(', '));
    buffer.write(')');

    final sql = buffer.toString();
    try {
      await db.execute(sql);
      // Verify table was created
      final exists = await _tableExists(db, info.tableName);
      if (!exists) {
        throw StateError(
            'Table ${info.tableName} was not created successfully');
      }
    } catch (e) {
      // If table already exists, that's OK (CREATE TABLE IF NOT EXISTS should handle this)
      // But if there's another error, log it and rethrow
      if (e.toString().contains('already exists') ||
          e.toString().contains('duplicate')) {
        // Table already exists, that's fine
        return;
      }
      print('Error creating table ${info.tableName}: $e');
      print('SQL: $sql');
      rethrow;
    }
  }

  String _buildColumnDefinition(String name, ColumnInfo info) {
    final buffer = StringBuffer();
    buffer.write('$name ${info.sqlType}');

    if (info.isPrimaryKey) {
      buffer.write(' PRIMARY KEY');
      if (info.autoIncrement) {
        buffer.write(' AUTOINCREMENT');
      }
    }

    if (!info.nullable && !info.isPrimaryKey) {
      buffer.write(' NOT NULL');
    }

    if (info.defaultValue != null) {
      buffer.write(' DEFAULT ${info.defaultValue}');
    }

    return buffer.toString();
  }

  /// Upgrade database from old version to new version
  ///
  /// Following sqflite best practices:
  /// - onCreate: Called when database is first created (creates all tables)
  /// - onUpgrade: Called when version increases (creates new tables, alters existing ones)
  ///
  /// This method ensures:
  /// 1. All tables exist (creates missing ones)
  /// 2. Existing tables get new columns added
  Future<void> upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
    List<Type> models,
  ) async {
    if (oldVersion < newVersion) {
      print('Upgrading database from version $oldVersion to $newVersion');

      // Process all models to ensure tables exist and have correct schema
      for (final modelType in models) {
        final info = ModelRegistry().getInfo(modelType);
        if (info == null) {
          print('Warning: Model $modelType not registered, skipping');
          continue;
        }

        try {
          // Check if table exists
          final tableExists = await _tableExists(db, info.tableName);

          if (!tableExists) {
            // Table doesn't exist - create it (new table in this version)
            await _createTable(db, info);
            print('✓ Created table ${info.tableName} during migration');
          } else {
            // Table exists - add missing columns (schema update)
            await _addMissingColumns(db, info);
          }
        } catch (e) {
          print('Error processing table ${info.tableName}: $e');
          // Try to create table anyway if there was an error
          try {
            await _createTable(db, info);
            print('✓ Created table ${info.tableName} after error recovery');
          } catch (createError) {
            print('✗ Failed to create table ${info.tableName}: $createError');
          }
        }
      }

      print('✓ Migration from version $oldVersion to $newVersion completed');
    }
  }

  Future<void> _addMissingColumns(Database db, ModelInfo info) async {
    try {
      // Get existing columns
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info('${info.tableName}')",
      );
      final existingColumns =
          tableInfo.map((row) => row['name'] as String).toSet();

      // Add missing columns
      for (final entry in info.columns.entries) {
        final columnName = entry.key;
        final columnInfo = entry.value;

        if (!existingColumns.contains(columnName)) {
          try {
            // Can't add PRIMARY KEY or AUTOINCREMENT with ALTER TABLE
            // So we build a simpler column definition
            final columnDef =
                _buildAlterColumnDefinition(columnName, columnInfo);
            await db.execute(
              'ALTER TABLE ${info.tableName} ADD COLUMN $columnDef',
            );
            print('Added column ${info.tableName}.$columnName');
          } catch (e) {
            // Ignore duplicate column errors
            if (!e.toString().contains('duplicate column')) {
              print('Error adding column ${info.tableName}.$columnName: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error adding columns to ${info.tableName}: $e');
    }
  }

  /// Check if a table exists
  ///
  /// Uses sqlite_master to check table existence (sqflite best practice)
  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      final exists = result.isNotEmpty;
      return exists;
    } catch (e) {
      // If query fails, assume table doesn't exist
      print('Warning: Error checking table existence for $tableName: $e');
      return false;
    }
  }

  /// Build column definition for ALTER TABLE (no PRIMARY KEY or AUTOINCREMENT)
  String _buildAlterColumnDefinition(String name, ColumnInfo info) {
    final buffer = StringBuffer();
    buffer.write('$name ${info.sqlType}');

    // Don't add PRIMARY KEY or AUTOINCREMENT in ALTER TABLE
    // These can only be set when creating the table

    if (!info.nullable && !info.isPrimaryKey) {
      buffer.write(' NOT NULL');
    }

    if (info.defaultValue != null) {
      buffer.write(' DEFAULT ${info.defaultValue}');
    }

    return buffer.toString();
  }
}
