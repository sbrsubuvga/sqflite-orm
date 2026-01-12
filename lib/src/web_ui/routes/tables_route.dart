import 'package:shelf/shelf.dart';
import 'package:sqflite_common/sqlite_api.dart' show Database;
import 'dart:convert';

/// Route handler for table operations
class TablesRoute {
  final Database _db;

  TablesRoute(this._db);

  /// List all tables
  Future<Response> listTables() async {
    try {
      final tables = await _db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );

      final tableList = tables
          .map((row) => {
                'name': row['name'] as String,
              })
          .toList();

      return Response.ok(
        jsonEncode({'tables': tableList}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get table information
  Future<Response> getTableInfo(String tableName) async {
    try {
      // Get table schema
      final tableInfo = await _db.rawQuery(
        "PRAGMA table_info('$tableName')",
      );

      // Get row count
      final countResult = await _db.rawQuery(
        "SELECT COUNT(*) as count FROM $tableName",
      );
      final count = countResult.first['count'] as int;

      final columns = tableInfo
          .map((row) => {
                'name': row['name'],
                'type': row['type'],
                'notnull': row['notnull'] == 1,
                'dflt_value': row['dflt_value'],
                'pk': row['pk'] == 1,
              })
          .toList();

      return Response.ok(
        jsonEncode({
          'name': tableName,
          'columns': columns,
          'rowCount': count,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.notFound(
        jsonEncode({'error': 'Table not found: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
