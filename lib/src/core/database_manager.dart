import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_orm/src/core/connection_pool.dart';
import 'package:sqflite_orm/src/core/migration_manager.dart';
import 'package:sqflite_orm/src/core/schema_validator.dart';
import 'package:sqflite_orm/src/models/base_model.dart';
import 'package:sqflite_orm/src/models/model_registrar.dart';
import 'package:sqflite_orm/src/models/model_registry.dart';
import 'package:sqflite_orm/src/query/query_builder.dart';
import 'package:sqflite_orm/src/web_ui/server.dart' show WebUI;

// Import Database type from sqflite_common_ffi
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database, Transaction;

/// Main database manager for cross-platform SQLite operations
class DatabaseManager {
  final String path;
  final int version;
  final List<Type> models;
  final Database? Function(Database db, int oldVersion, int newVersion)?
      onUpgrade;
  final Database? Function(Database db, int version)? onCreate;

  Database? _database;
  final ConnectionPool _connectionPool = ConnectionPool();
  final MigrationManager _migrationManager = MigrationManager();
  final SchemaValidator _schemaValidator = SchemaValidator();

  static bool _ffiInitialized = false;

  DatabaseManager({
    required this.path,
    required this.version,
    required this.models,
    this.onUpgrade,
    this.onCreate,
  });

  /// Initialize FFI for desktop platforms (called automatically)
  /// This is safe to call multiple times - it only initializes once
  static void _ensureFfiInitialized() {
    if (_ffiInitialized) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      ffi.sqfliteFfiInit();
      ffi.databaseFactory = ffi.databaseFactoryFfiNoIsolate;
      _ffiInitialized = true;
    }
  }

  /// Initialize the database manager
  ///
  /// Automatically registers models if they're not already registered.
  /// Models are auto-registered by creating an instance and inferring
  /// column information from toMap().
  ///
  /// You can optionally provide instance creators for models:
  /// ```dart
  /// final db = await DatabaseManager.initialize(
  ///   path: 'app.db',
  ///   version: 1,
  ///   models: [User],
  ///   instanceCreators: {User: () => User()},
  /// );
  /// ```
  ///
  /// Enable web debug mode to automatically start Web UI:
  /// ```dart
  /// final db = await DatabaseManager.initialize(
  ///   path: 'app.db',
  ///   version: 1,
  ///   models: [User],
  ///   webDebug: true,  // Automatically starts Web UI
  ///   webDebugPort: 4800,  // Optional: custom port (default: 4800)
  ///   webDebugPassword: 'secret',  // Optional: password protection
  /// );
  /// ```
  static Future<DatabaseManager> initialize({
    required String path,
    required int version,
    required List<Type> models,
    Map<Type, BaseModel Function()>? instanceCreators,
    Database? Function(Database db, int oldVersion, int newVersion)? onUpgrade,
    Database? Function(Database db, int version)? onCreate,
    bool webDebug = false,
    int webDebugPort = 4800,
    String? webDebugPassword,
  }) async {
    // Register instance creators if provided
    if (instanceCreators != null) {
      for (final entry in instanceCreators.entries) {
        _instanceCreators[entry.key] = entry.value;
      }
    }

    // Auto-register models that aren't already registered
    await _autoRegisterModels(models);

    final manager = DatabaseManager(
      path: path,
      version: version,
      models: models,
      onUpgrade: onUpgrade,
      onCreate: onCreate,
    );

    await manager._initializeDatabase();

    // Start Web UI if web debug mode is enabled
    if (webDebug) {
      try {
        await WebUI.start(
          manager.database,
          port: webDebugPort,
          password: webDebugPassword,
        );
      } catch (e) {
        print('⚠️  Failed to start Web UI: $e');
        // Don't fail initialization if Web UI fails to start
      }
    }

    return manager;
  }

  /// Auto-register models by creating instances and inferring information
  static Future<void> _autoRegisterModels(List<Type> models) async {
    final registry = ModelRegistry();

    for (final modelType in models) {
      // Skip if already registered
      if (registry.getInfo(modelType) != null) {
        continue;
      }

      try {
        // Try to create an instance using a workaround
        // Since we can't use reflection, we'll use a pattern where
        // models must have a default constructor
        final instance = _createModelInstance(modelType);
        if (instance == null) {
          print(
              'Warning: Could not auto-register $modelType - ensure it has a default constructor');
          continue;
        }

        // Extract information from the model
        final tableName = instance.tableName;
        final map = instance.toMap();

        // Try to detect primary key (common patterns: 'id', first key, etc.)
        String? primaryKey = _detectPrimaryKey(map, modelType);

        // Infer columns from toMap()
        final columns =
            SimpleModelRegistrar.inferColumnsFromModel(instance, primaryKey);

        // Create factory from fromMap
        final factory = (Map<String, dynamic> map) {
          final newInstance = _createModelInstance(modelType);
          if (newInstance == null) {
            throw StateError('Failed to create instance of $modelType');
          }
          return newInstance.fromMap(map);
        };

        // Register the model
        final modelInfo = ModelInfo(
          tableName: tableName,
          modelType: modelType,
          columns: columns,
          primaryKey: primaryKey,
          factory: factory,
        );

        registry.register(modelType, modelInfo);
      } catch (e) {
        print('Warning: Failed to auto-register $modelType: $e');
      }
    }
  }

  /// Create a model instance using a registry of instance creators
  static BaseModel? _createModelInstance(Type modelType) {
    // Try to get instance creator from global registry
    final creator = _instanceCreators[modelType];
    if (creator != null) {
      return creator();
    }

    // If no creator registered, we can't auto-register
    // User should either:
    // 1. Register models manually before initialize()
    // 2. Use code generation to provide instance creators
    return null;
  }

  /// Global registry for model instance creators
  /// Used for auto-registration
  static final Map<Type, BaseModel Function()> _instanceCreators = {};

  /// Register an instance creator for auto-registration
  /// This allows models to be auto-registered during DatabaseManager.initialize()
  static void registerInstanceCreator<T extends BaseModel>(
      T Function() creator) {
    _instanceCreators[T] = creator;
  }

  /// Detect primary key from common patterns
  static String? _detectPrimaryKey(Map<String, dynamic> map, Type modelType) {
    // Common primary key names
    if (map.containsKey('id')) return 'id';
    if (map.containsKey('ID')) return 'ID';
    if (map.containsKey('Id')) return 'Id';

    // Check for fields that are null (likely auto-increment primary keys)
    for (final entry in map.entries) {
      if (entry.value == null) {
        final key = entry.key.toLowerCase();
        if (key.contains('id')) {
          return entry.key;
        }
      }
    }

    // Return first key if only one key exists
    if (map.length == 1) {
      return map.keys.first;
    }

    return null;
  }

  Future<void> _initializeDatabase() async {
    // Initialize FFI for desktop platforms (if needed)
    _ensureFfiInitialized();

    // Get database path
    final dbPath = await _getDatabasePath(path);

    // Open database using the appropriate factory
    // FFI is initialized automatically for desktop platforms
    // For mobile platforms, the default factory is used
    _database = await ffi.databaseFactory.openDatabase(
      dbPath,
      options: ffi.OpenDatabaseOptions(
        version: version,
        onCreate: (db, version) async {
          // Database is being created for the first time
          // Create all tables for all models
          print('Creating new database (version $version)');
          await _migrationManager.createTables(db, models);
          if (onCreate != null) {
            onCreate!(db, version);
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Database exists with old version, upgrade to new version
          // This handles: creating new tables, adding columns to existing tables
          print('Upgrading database from version $oldVersion to $newVersion');
          await _migrationManager.upgradeDatabase(
            db,
            oldVersion,
            newVersion,
            models,
          );
          if (onUpgrade != null) {
            onUpgrade!(db, oldVersion, newVersion);
          }
        },
      ),
    );

    // Validate schema (only if models are registered)
    try {
      await _schemaValidator.validate(_database!, models);
    } catch (e) {
      print('Schema validation warning: $e');
      // Continue even if validation fails - models might not be registered yet
    }
  }

  /// Get the database instance
  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Create a query builder for a model type
  QueryBuilder<T> query<T extends BaseModel>() {
    return QueryBuilder<T>(database, T);
  }

  /// Create a query builder for a model type using a transaction
  ///
  /// Use this inside transaction callbacks to ensure all operations
  /// use the transaction object (sqflite best practice).
  ///
  /// Example:
  /// ```dart
  /// await db.transaction((txn) async {
  ///   final user = await db.queryWithTransaction<User>(txn).create({...});
  /// });
  /// ```
  QueryBuilder<T> queryWithTransaction<T extends BaseModel>(Transaction txn) {
    return QueryBuilder<T>(txn as dynamic, T);
  }

  /// Execute a transaction
  ///
  /// All database operations inside the transaction must use the
  /// transaction object (txn), not the main database object.
  ///
  /// Example:
  /// ```dart
  /// await db.transaction((txn) async {
  ///   final user = await db.queryWithTransaction<User>(txn).create({...});
  ///   // or use raw SQL: await txn.execute('INSERT INTO ...');
  /// });
  /// ```
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return await database.transaction(action);
  }

  /// Close the database
  Future<void> close() async {
    await _connectionPool.close();
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get database path (works for both Flutter and pure Dart)
  Future<String> _getDatabasePath(String relativePath) async {
    // Try to use path_provider if available (Flutter environment)
    try {
      return await _getPathWithProvider(relativePath);
    } catch (e) {
      // Fallback for pure Dart: use current directory
      // If path is absolute, use it directly
      if (relativePath.startsWith('/') ||
          (Platform.isWindows && relativePath.contains(':'))) {
        return relativePath;
      }
      return relativePath; // Use relative to current directory
    }
  }

  /// Try to get path using path_provider (Flutter only)
  Future<String> _getPathWithProvider(String relativePath) async {
    // Dynamic import attempt - will fail gracefully if path_provider not available
    try {
      // For desktop
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final pathProvider = await _tryGetPathProvider();
        if (pathProvider != null) {
          final dir = await pathProvider.getApplicationSupportDirectory();
          return '${dir.path}/$relativePath';
        }
      } else {
        // For mobile
        final pathProvider = await _tryGetPathProvider();
        if (pathProvider != null) {
          final databasesPath = await pathProvider.getDatabasesPath();
          return '$databasesPath/$relativePath';
        }
      }
    } catch (e) {
      // path_provider not available
    }
    // Fallback
    return relativePath;
  }

  /// Try to dynamically access path_provider
  Future<dynamic> _tryGetPathProvider() async {
    // This will only work in Flutter environment
    // For pure Dart, it will return null
    return null;
  }
}
