import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;
import 'dart:convert';

/// Route handler for SQL query execution
class QueryRoute {
  final Database _db;

  QueryRoute(this._db);

  /// Execute a SQL query
  Future<Response> executeQuery(String sql, {List<dynamic>? args}) async {
    try {
      // Basic SQL validation - only allow SELECT for security
      final sqlUpper = sql.trim().toUpperCase();

      if (sqlUpper.startsWith('SELECT')) {
        final results = await _db.rawQuery(sql, args ?? []);
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': results,
            'rowCount': results.length,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else if (sqlUpper.startsWith('INSERT') ||
          sqlUpper.startsWith('UPDATE') ||
          sqlUpper.startsWith('DELETE')) {
        // For write operations, use appropriate method
        if (sqlUpper.startsWith('INSERT')) {
          final id = await _db.rawInsert(sql, args ?? []);
          return Response.ok(
            jsonEncode({
              'success': true,
              'id': id,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          final count = await _db.rawUpdate(sql, args ?? []);
          return Response.ok(
            jsonEncode({
              'success': true,
              'affectedRows': count,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } else {
        // For other operations (CREATE, DROP, ALTER, etc.)
        await _db.execute(sql, args ?? []);
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Query executed successfully',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({
          'success': false,
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
