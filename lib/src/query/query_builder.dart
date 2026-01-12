// ignore: unused_import
import 'package:sqflite_common/sqlite_api.dart' show Database, Transaction;
import 'package:sqflite_orm/src/models/base_model.dart';
import 'package:sqflite_orm/src/models/model_registry.dart';
import 'package:sqflite_orm/src/query/where_clause.dart';
import 'package:sqflite_orm/src/relationships/association_loader.dart';

/// Fluent query builder for type-safe database queries
///
/// Can work with both Database and Transaction objects.
/// When inside a transaction, always use the Transaction object.
class QueryBuilder<T extends BaseModel> {
  // Accept both Database and Transaction since they share the same interface
  // for rawQuery, rawInsert, rawUpdate, rawDelete operations
  // Type: Database | Transaction
  final dynamic _db;
  final Type _modelType;
  final ModelInfo? _modelInfo;

  WhereClause? _whereClause;
  String? _orderBy;
  bool _orderDesc = false;
  int? _limit;
  int? _offset;
  List<String> _relations = [];
  List<String> _selectColumns = [];

  /// Create a query builder with a Database or Transaction
  ///
  /// When inside a transaction callback, pass the Transaction object
  /// to ensure all operations use the transaction.
  QueryBuilder(this._db, this._modelType)
      : _modelInfo = ModelRegistry().getInfo(_modelType);

  /// Add a WHERE clause
  QueryBuilder<T> where(String column) {
    _whereClause = WhereClause();
    return this;
  }

  /// Add equality condition
  QueryBuilder<T> equals(dynamic value) {
    if (_whereClause == null) {
      throw StateError('Call where() first before using equals()');
    }
    // This is a simplified version - in practice, you'd track the column name
    return this;
  }

  /// Add greater than condition
  QueryBuilder<T> greaterThan(dynamic value) {
    if (_whereClause == null) {
      throw StateError('Call where() first before using greaterThan()');
    }
    return this;
  }

  /// Add less than condition
  QueryBuilder<T> lessThan(dynamic value) {
    if (_whereClause == null) {
      throw StateError('Call where() first before using lessThan()');
    }
    return this;
  }

  /// Add WHERE condition using a [WhereClause] builder.
  ///
  /// This is the recommended way to add WHERE conditions.
  ///
  /// Example:
  /// ```dart
  /// final users = await db.query<User>()
  ///   .whereClause(WhereClause()
  ///     .equals('status', 'active')
  ///     .greaterThan('age', 18))
  ///   .findAll();
  /// ```
  QueryBuilder<T> whereClause(WhereClause clause) {
    _whereClause = clause;
    return this;
  }

  /// Add ORDER BY clause to sort results.
  ///
  /// Example:
  /// ```dart
  /// final users = await db.query<User>()
  ///   .orderBy('createdAt', descending: true)
  ///   .findAll();
  /// ```
  QueryBuilder<T> orderBy(String column, {bool descending = false}) {
    _orderBy = column;
    _orderDesc = descending;
    return this;
  }

  /// Add LIMIT clause to restrict the number of results.
  ///
  /// Example:
  /// ```dart
  /// final users = await db.query<User>()
  ///   .limit(10)
  ///   .findAll();
  /// ```
  QueryBuilder<T> limit(int count) {
    _limit = count;
    return this;
  }

  /// Add OFFSET clause for pagination.
  ///
  /// Typically used with [limit] for pagination.
  ///
  /// Example:
  /// ```dart
  /// final users = await db.query<User>()
  ///   .limit(10)
  ///   .offset(20)
  ///   .findAll();
  /// ```
  QueryBuilder<T> offset(int count) {
    _offset = count;
    return this;
  }

  /// Include relationships (eager loading)
  ///
  /// Alias for `include()` - Sequelize-style method name
  ///
  /// Example:
  /// ```dart
  /// final posts = await db.query<Post>()
  ///   .withRelations(['author', 'comments'])
  ///   .findAll();
  /// ```
  QueryBuilder<T> withRelations(List<String> relations) {
    _relations = relations;
    return this;
  }

  /// Include associations (eager loading) - Sequelize-style
  ///
  /// Alias for `withRelations()` - provides Sequelize-compatible API
  ///
  /// Example:
  /// ```dart
  /// final posts = await db.query<Post>()
  ///   .include(['author', 'comments'])
  ///   .findAll();
  ///
  /// final post = await db.query<Post>()
  ///   .include(['author'])
  ///   .findOne();
  /// ```
  QueryBuilder<T> include(List<String> associations) {
    _relations = associations;
    return this;
  }

  /// Select specific columns instead of all columns.
  ///
  /// Example:
  /// ```dart
  /// final users = await db.query<User>()
  ///   .select(['id', 'name', 'email'])
  ///   .findAll();
  /// ```
  QueryBuilder<T> select(List<String> columns) {
    _selectColumns = columns;
    return this;
  }

  /// Find all matching records
  ///
  /// Returns a list of all matching records.
  /// Supports eager loading via `include()` or `withRelations()`.
  ///
  /// Example:
  /// ```dart
  /// // Without associations
  /// final users = await db.query<User>().findAll();
  ///
  /// // With associations (eager loading)
  /// final posts = await db.query<Post>()
  ///   .include(['author', 'comments'])
  ///   .whereClause(WhereClause().equals('published', 1))
  ///   .findAll();
  ///
  /// // Access loaded associations
  /// for (final post in posts) {
  ///   final author = post.getRelation<User>('author');
  ///   final comments = post.getRelationList<Comment>('comments');
  /// }
  /// ```
  Future<List<T>> findAll() async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final tableName = _modelInfo!.tableName;
    final columns = _selectColumns.isEmpty ? '*' : _selectColumns.join(', ');

    var query = 'SELECT $columns FROM $tableName';

    final args = <dynamic>[];

    if (_whereClause != null && _whereClause!.conditions.isNotEmpty) {
      query += ' ${_whereClause!.build()}';
      args.addAll(_whereClause!.args);
    }

    if (_orderBy != null) {
      query += ' ORDER BY $_orderBy';
      if (_orderDesc) {
        query += ' DESC';
      }
    }

    if (_limit != null) {
      query += ' LIMIT $_limit';
    }

    if (_offset != null) {
      query += ' OFFSET $_offset';
    }

    final results = await _db.rawQuery(query, args);
    final models = <T>[];

    for (final row in results) {
      final model = _createModelFromMap(row);
      if (model != null) {
        models.add(model);
      }
    }

    // Load relationships if requested
    if (_relations.isNotEmpty) {
      await AssociationLoader()
          .loadRelations(_db, models, _relations, _modelInfo!);
    }

    return models;
  }

  /// Find first matching record
  ///
  /// Returns the first matching record or null if none found.
  /// Supports eager loading via `include()` or `withRelations()`.
  ///
  /// Example:
  /// ```dart
  /// final user = await db.query<User>()
  ///   .whereClause(WhereClause().equals('email', 'john@example.com'))
  ///   .include(['posts'])
  ///   .findFirst();
  /// ```
  Future<T?> findFirst() async {
    final results = await limit(1).findAll();
    return results.isNotEmpty ? results.first : null;
  }

  /// Find one matching record - Sequelize-style alias
  ///
  /// Alias for `findFirst()` - provides Sequelize-compatible API.
  /// Returns the first matching record or null if none found.
  /// Supports eager loading via `include()` or `withRelations()`.
  ///
  /// Example:
  /// ```dart
  /// final user = await db.query<User>()
  ///   .whereClause(WhereClause().equals('email', 'john@example.com'))
  ///   .include(['posts', 'comments'])
  ///   .findOne();
  /// ```
  Future<T?> findOne() async {
    return findFirst();
  }

  /// Find a record by primary key
  ///
  /// Similar to Sequelize's findByPk method.
  /// Returns the model instance if found, null otherwise.
  /// Supports eager loading via `include()` or `withRelations()`.
  ///
  /// Example:
  /// ```dart
  /// // Without associations
  /// final user = await db.query<User>().findByPk(123);
  ///
  /// // With associations (eager loading)
  /// final user = await db.query<User>()
  ///   .include(['posts', 'comments'])
  ///   .findByPk(123);
  /// ```
  Future<T?> findByPk(dynamic primaryKeyValue) async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final primaryKey = _modelInfo!.primaryKey;
    if (primaryKey == null) {
      throw StateError(
          'Model $_modelType does not have a primary key defined');
    }

    final tableName = _modelInfo!.tableName;
    final columns = _selectColumns.isEmpty ? '*' : _selectColumns.join(', ');

    var query = 'SELECT $columns FROM $tableName WHERE $primaryKey = ?';
    final args = <dynamic>[primaryKeyValue];

    // Apply ORDER BY if set (though typically not needed for single record)
    if (_orderBy != null) {
      query += ' ORDER BY $_orderBy';
      if (_orderDesc) {
        query += ' DESC';
      }
    }

    // Limit to 1 since we're looking for a single record
    query += ' LIMIT 1';

    final results = await _db.rawQuery(query, args);

    if (results.isEmpty) {
      return null;
    }

    final model = _createModelFromMap(results.first);
    if (model == null) {
      return null;
    }

    // Load relationships if requested
    if (_relations.isNotEmpty) {
      await AssociationLoader()
          .loadRelations(_db, [model], _relations, _modelInfo!);
    }

    return model;
  }

  /// Count matching records.
  ///
  /// Returns the number of records that match the current query conditions.
  ///
  /// Example:
  /// ```dart
  /// final count = await db.query<User>()
  ///   .whereClause(WhereClause().equals('status', 'active'))
  ///   .count();
  /// ```
  Future<int> count() async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final tableName = _modelInfo!.tableName;
    var query = 'SELECT COUNT(*) as count FROM $tableName';

    final args = <dynamic>[];

    if (_whereClause != null && _whereClause!.conditions.isNotEmpty) {
      query += ' ${_whereClause!.build()}';
      args.addAll(_whereClause!.args);
    }

    final result = await _db.rawQuery(query, args);
    return result.first['count'] as int;
  }

  /// Delete matching records.
  ///
  /// Returns the number of deleted records.
  /// **Warning**: If no WHERE clause is specified, all records will be deleted.
  ///
  /// Example:
  /// ```dart
  /// final deleted = await db.query<User>()
  ///   .whereClause(WhereClause().equals('id', 123))
  ///   .delete();
  /// ```
  Future<int> delete() async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final tableName = _modelInfo!.tableName;
    var query = 'DELETE FROM $tableName';

    final args = <dynamic>[];

    if (_whereClause != null && _whereClause!.conditions.isNotEmpty) {
      query += ' ${_whereClause!.build()}';
      args.addAll(_whereClause!.args);
    }

    return await _db.rawDelete(query, args);
  }

  /// Create a new record (Sequelize-style)
  ///
  /// Similar to Sequelize's Model.create()
  /// Accepts a `Map<String, dynamic>` and returns the created model instance
  ///
  /// Example:
  /// ```dart
  /// final user = await db.query<User>().create({
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  /// });
  /// ```
  Future<T> create(Map<String, dynamic> values) async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final tableName = _modelInfo!.tableName;
    final primaryKey = _modelInfo!.primaryKey;

    // Remove null values and primary key if auto-increment
    final data = Map<String, dynamic>.from(values);
    if (primaryKey != null) {
      final primaryKeyColumn = _modelInfo!.columns[primaryKey];
      if (primaryKeyColumn?.autoIncrement == true) {
        data.remove(primaryKey);
      }
    }

    // Convert DateTime to String and bool to int for SQLite
    data.forEach((key, value) {
      if (value is DateTime) {
        data[key] = value.toIso8601String();
      } else if (value is bool) {
        data[key] = value ? 1 : 0;
      }
    });

    // Remove null values to use database defaults
    data.removeWhere((key, value) => value == null);

    if (data.isEmpty) {
      throw ArgumentError('Cannot create empty record');
    }

    final columns = data.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final args = data.values.toList();

    final query =
        'INSERT INTO $tableName (${columns.join(', ')}) VALUES ($placeholders)';

    final insertedId = await _db.rawInsert(query, args);

    // Fetch the created record to return as model instance
    if (primaryKey != null && insertedId > 0) {
      final created = await findByPk(insertedId);
      if (created != null) {
        return created;
      }
    }

    // If we can't fetch it, create a model from the inserted data
    final resultData = Map<String, dynamic>.from(data);
    if (primaryKey != null && insertedId > 0) {
      resultData[primaryKey] = insertedId;
    }
    final model = _createModelFromMap(resultData);
    if (model == null) {
      throw StateError('Failed to create model instance');
    }
    return model;
  }

  /// Insert a new record using a model instance
  ///
  /// Similar to Sequelize's instance.save() for new records
  /// Returns the inserted row ID
  ///
  /// Example:
  /// ```dart
  /// final user = User()..name = 'John'..email = 'john@example.com';
  /// final id = await db.query<User>().insert(user);
  /// ```
  Future<int> insert(T model) async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final tableName = _modelInfo!.tableName;
    Map<String, dynamic> values = model.toMap();

    // Remove null values and primary key if auto-increment
    final primaryKey = _modelInfo!.primaryKey;
    if (primaryKey != null) {
      final primaryKeyColumn = _modelInfo!.columns[primaryKey];
      if (primaryKeyColumn?.autoIncrement == true) {
        values.remove(primaryKey);
      }
    }

    // Convert DateTime to String and bool to int for SQLite
    values.forEach((key, value) {
      if (value is DateTime) {
        values[key] = value.toIso8601String();
      } else if (value is bool) {
        values[key] = value ? 1 : 0;
      }
    });

    // Remove null values to use database defaults
    values.removeWhere((key, value) => value == null);

    if (values.isEmpty) {
      throw ArgumentError('Cannot insert empty record');
    }

    final columns = values.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final args = values.values.toList();

    final query =
        'INSERT INTO $tableName (${columns.join(', ')}) VALUES ($placeholders)';

    return await _db.rawInsert(query, args);
  }

  /// Update records (Sequelize-style)
  ///
  /// Similar to Sequelize's Model.update() with WHERE clause
  /// Accepts a `Map<String, dynamic>` of values and uses WHERE clause if present
  /// Returns the number of affected rows
  ///
  /// Example:
  /// ```dart
  /// final rows = await db.query<User>()
  ///   .whereClause(WhereClause().equals('id', 1))
  ///   .updateValues({'name': 'Updated Name'});
  /// ```
  Future<int> updateValues(Map<String, dynamic> values) async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    if (values.isEmpty) {
      throw ArgumentError('Cannot update with empty values');
    }

    // Convert DateTime to String and bool to int for SQLite
    final processedValues = Map<String, dynamic>.from(values);
    processedValues.forEach((key, value) {
      if (value is DateTime) {
        processedValues[key] = value.toIso8601String();
      } else if (value is bool) {
        processedValues[key] = value ? 1 : 0;
      }
    });

    final tableName = _modelInfo!.tableName;
    final columns = processedValues.keys.toList();
    final setClause = columns.map((col) => '$col = ?').join(', ');
    final args = <dynamic>[...processedValues.values];

    var query = 'UPDATE $tableName SET $setClause';

    if (_whereClause != null && _whereClause!.conditions.isNotEmpty) {
      query += ' ${_whereClause!.build()}';
      args.addAll(_whereClause!.args);
    } else {
      // Warn if no WHERE clause - updating all records
      // In production, you might want to throw an error instead
      print(
          'Warning: updateValues() called without WHERE clause - will update all records');
    }

    return await _db.rawUpdate(query, args);
  }

  /// Update a model instance (Sequelize-style)
  ///
  /// Similar to Sequelize's instance.save() or instance.update()
  /// Automatically uses the model's primary key for the WHERE clause
  /// Returns the number of affected rows (typically 1)
  ///
  /// Example:
  /// ```dart
  /// final user = await db.query<User>().findByPk(1);
  /// user.name = 'Updated Name';
  /// await db.query<User>().update(user);
  /// ```
  Future<int> update(T model) async {
    if (_modelInfo == null) {
      throw StateError('Model $_modelType not registered');
    }

    final primaryKey = _modelInfo!.primaryKey;
    if (primaryKey == null) {
      throw StateError(
          'Model $_modelType does not have a primary key defined');
    }

    final values = model.toMap();
    final primaryKeyValue = values[primaryKey];

    if (primaryKeyValue == null) {
      throw ArgumentError(
          'Cannot update model without primary key value. Use insert() for new records.');
    }

    // Remove primary key from update values
    final updateValues = Map<String, dynamic>.from(values);
    updateValues.remove(primaryKey);

    // Convert DateTime to String and bool to int for SQLite
    updateValues.forEach((key, value) {
      if (value is DateTime) {
        updateValues[key] = value.toIso8601String();
      } else if (value is bool) {
        updateValues[key] = value ? 1 : 0;
      }
    });

    if (updateValues.isEmpty) {
      throw ArgumentError('Cannot update with empty values');
    }

    final tableName = _modelInfo!.tableName;
    final columns = updateValues.keys.toList();
    final setClause = columns.map((col) => '$col = ?').join(', ');
    final args = <dynamic>[...updateValues.values, primaryKeyValue]
      
      ;

    final query = 'UPDATE $tableName SET $setClause WHERE $primaryKey = ?';

    return await _db.rawUpdate(query, args);
  }

  T? _createModelFromMap(Map<String, dynamic> map) {
    if (_modelInfo == null) {
      return null;
    }

    // Use factory function if provided
    if (_modelInfo!.factory != null) {
      try {
        final instance = _modelInfo!.factory!(map) as T;
        return instance;
      } catch (e) {
        return null;
      }
    }

    // Fallback: try to use fromMap pattern
    // This requires the model to have a default constructor
    // and fromMap to create a new instance
    // Note: This is a limitation - without reflection or factory,
    // we can't create instances generically
    return null;
  }
}
