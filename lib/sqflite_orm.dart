/// SQLite ORM package for Flutter/Dart
/// 
/// A comprehensive ORM solution with cross-platform support,
/// automatic migrations, relationship handling, and query builder.
library sqflite_orm;

// Core exports
export 'src/core/database_manager.dart';
export 'src/core/migration_manager.dart';
export 'src/core/schema_validator.dart';
export 'src/core/connection_pool.dart';

// Annotations
export 'src/annotations/table.dart';
export 'src/annotations/column.dart';
export 'src/annotations/primary_key.dart';
export 'src/annotations/foreign_key.dart';
export 'src/annotations/relationship.dart';

// Models
export 'src/models/base_model.dart';
export 'src/models/model_registry.dart';
export 'src/models/model_registrar.dart';

// Query
export 'src/query/query_builder.dart';
export 'src/query/where_clause.dart';
export 'src/query/query_result.dart';

// Relationships
export 'src/relationships/relationship_manager.dart';
export 'src/relationships/association_loader.dart';

// Transactions
export 'src/transactions/transaction_manager.dart';

