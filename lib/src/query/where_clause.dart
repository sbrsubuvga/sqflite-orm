/// Builder for WHERE clauses
class WhereClause {
  final List<String> conditions = [];
  final List<dynamic> arguments = [];

  /// Add an equality condition
  WhereClause equals(String column, dynamic value) {
    conditions.add('$column = ?');
    arguments.add(value);
    return this;
  }

  /// Add a not-equal condition
  WhereClause notEquals(String column, dynamic value) {
    conditions.add('$column != ?');
    arguments.add(value);
    return this;
  }

  /// Add a greater than condition
  WhereClause greaterThan(String column, dynamic value) {
    conditions.add('$column > ?');
    arguments.add(value);
    return this;
  }

  /// Add a less than condition
  WhereClause lessThan(String column, dynamic value) {
    conditions.add('$column < ?');
    arguments.add(value);
    return this;
  }

  /// Add a greater than or equal condition
  WhereClause greaterThanOrEqual(String column, dynamic value) {
    conditions.add('$column >= ?');
    arguments.add(value);
    return this;
  }

  /// Add a less than or equal condition
  WhereClause lessThanOrEqual(String column, dynamic value) {
    conditions.add('$column <= ?');
    arguments.add(value);
    return this;
  }

  /// Add a LIKE condition
  WhereClause like(String column, String pattern) {
    conditions.add('$column LIKE ?');
    arguments.add(pattern);
    return this;
  }

  /// Add an IN condition
  WhereClause inList(String column, List<dynamic> values) {
    if (values.isEmpty) {
      conditions.add('1 = 0'); // Always false
      return this;
    }
    final placeholders = List.filled(values.length, '?').join(', ');
    conditions.add('$column IN ($placeholders)');
    arguments.addAll(values);
    return this;
  }

  /// Add an IS NULL condition
  WhereClause isNull(String column) {
    conditions.add('$column IS NULL');
    return this;
  }

  /// Add an IS NOT NULL condition
  WhereClause isNotNull(String column) {
    conditions.add('$column IS NOT NULL');
    return this;
  }

  /// Add an AND condition
  WhereClause and(WhereClause other) {
    conditions.addAll(other.conditions);
    arguments.addAll(other.arguments);
    return this;
  }

  /// Add an OR condition (wraps current conditions)
  WhereClause or(WhereClause other) {
    if (conditions.isNotEmpty) {
      final current = conditions.join(' AND ');
      conditions.clear();
      conditions.add('($current OR ${other.conditions.join(' AND ')})');
      arguments.addAll(other.arguments);
    } else {
      conditions.addAll(other.conditions);
      arguments.addAll(other.arguments);
    }
    return this;
  }

  /// Build the WHERE clause string
  String build() {
    if (conditions.isEmpty) return '';
    return 'WHERE ${conditions.join(' AND ')}';
  }

  /// Get the arguments for the WHERE clause
  List<dynamic> get args => arguments;
}

