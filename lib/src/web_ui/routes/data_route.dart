import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;
import 'dart:convert';

/// Route handler for data CRUD operations
class DataRoute {
  final Database _db;

  DataRoute(this._db);

  /// Get table data with pagination
  Future<Response> getTableData(
    String tableName, {
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    bool? sortDesc,
  }) async {
    try {
      page ??= 1;
      pageSize ??= 50;
      final offset = (page - 1) * pageSize;

      var query = 'SELECT * FROM $tableName';
      final args = <dynamic>[];

      if (search != null && search.isNotEmpty) {
        // Get column names for search
        final tableInfo = await _db.rawQuery("PRAGMA table_info('$tableName')");
        final columnNames = tableInfo
            .map((row) => row['name'] as String)
            .where((name) => name.toLowerCase().contains('text') ||
                name.toLowerCase().contains('name') ||
                name.toLowerCase().contains('id'))
            .toList();

        if (columnNames.isNotEmpty) {
          final conditions = columnNames
              .map((col) => '$col LIKE ?')
              .join(' OR ');
          query += ' WHERE $conditions';
          args.addAll(List.filled(columnNames.length, '%$search%'));
        }
      }

      if (sortBy != null) {
        query += ' ORDER BY $sortBy';
        if (sortDesc == true) {
          query += ' DESC';
        }
      }

      query += ' LIMIT $pageSize OFFSET $offset';

      final data = await _db.rawQuery(query, args);
      final countResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName',
      );
      final totalCount = countResult.first['count'] as int;

      return Response.ok(
        jsonEncode({
          'data': data,
          'pagination': {
            'page': page,
            'pageSize': pageSize,
            'totalCount': totalCount,
            'totalPages': (totalCount / pageSize).ceil(),
          },
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

  /// Insert a new row
  Future<Response> insertRow(String tableName, Map<String, dynamic> data) async {
    try {
      final id = await _db.insert(tableName, data);
      return Response.ok(
        jsonEncode({'id': id, 'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Update a row
  Future<Response> updateRow(
    String tableName,
    String idColumn,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    try {
      final count = await _db.update(
        tableName,
        data,
        where: '$idColumn = ?',
        whereArgs: [id],
      );

      return Response.ok(
        jsonEncode({'updated': count, 'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Delete a row
  Future<Response> deleteRow(String tableName, String idColumn, dynamic id) async {
    try {
      final count = await _db.delete(
        tableName,
        where: '$idColumn = ?',
        whereArgs: [id],
      );

      return Response.ok(
        jsonEncode({'deleted': count, 'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}

