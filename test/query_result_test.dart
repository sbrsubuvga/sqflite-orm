import 'package:sqflite_orm/sqflite_orm.dart';
import 'package:test/test.dart';

void main() {
  group('QueryResult', () {
    test('creates query result with required fields', () {
      final data = [1, 2, 3];
      final result = QueryResult<int>(
        data: data,
        totalCount: 100,
        page: 1,
        pageSize: 10,
      );

      expect(result.data, data);
      expect(result.totalCount, 100);
      expect(result.page, 1);
      expect(result.pageSize, 10);
    });

    test('creates query result with defaults', () {
      final data = [1, 2, 3];
      final result = QueryResult<int>(
        data: data,
      );

      expect(result.data, data);
      expect(result.totalCount, isNull);
      expect(result.page, 1);
      expect(result.pageSize, 0);
    });

    test('hasMore returns true when more pages exist', () {
      final result = QueryResult<int>(
        data: [1, 2, 3],
        totalCount: 100,
        page: 1,
        pageSize: 10,
      );

      expect(result.hasMore, isTrue);
    });

    test('hasMore returns false when on last page', () {
      final result = QueryResult<int>(
        data: [1, 2, 3],
        totalCount: 13,
        page: 2,
        pageSize: 10,
      );

      expect(result.hasMore, isFalse);
    });

    test('hasMore returns false when totalCount is null', () {
      final result = QueryResult<int>(
        data: [1, 2, 3],
        totalCount: null,
        page: 1,
        pageSize: 10,
      );

      expect(result.hasMore, isFalse);
    });

    test('totalPages calculates correctly', () {
      final result = QueryResult<int>(
        data: [1, 2, 3],
        totalCount: 25,
        page: 1,
        pageSize: 10,
      );

      expect(result.totalPages, 3); // 25 / 10 = 2.5, ceil = 3
    });

    test('totalPages returns null when totalCount is null', () {
      final result = QueryResult<int>(
        data: [1, 2, 3],
        totalCount: null,
        page: 1,
        pageSize: 10,
      );

      expect(result.totalPages, isNull);
    });

    test('totalPages returns null when pageSize is 0', () {
      final result = QueryResult<int>(
        data: [1, 2, 3],
        totalCount: 100,
        page: 1,
        pageSize: 0,
      );

      expect(result.totalPages, isNull);
    });

    test('totalPages handles exact division', () {
      final result = QueryResult<int>(
        data: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        totalCount: 20,
        page: 1,
        pageSize: 10,
      );

      expect(result.totalPages, 2);
    });
  });
}
