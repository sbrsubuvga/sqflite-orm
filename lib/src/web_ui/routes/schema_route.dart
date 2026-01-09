import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;
import 'dart:convert';

/// Route handler for schema introspection
class SchemaRoute {
  final Database _db;

  SchemaRoute(this._db);

  /// Get table schema
  Future<Response> getTableSchema(Request request, String tableName) async {
    try {
      final tableInfo = await _db.rawQuery(
        "PRAGMA table_info('$tableName')",
      );

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
          'table': tableName,
          'columns': columns,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get all tables
  Future<Response> getAllTables() async {
    try {
      final tables = await _db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final tableNames = tables.map((row) => row['name'] as String).toList();

      return Response.ok(
        jsonEncode({'tables': tableNames}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
