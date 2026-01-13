import 'package:sqflite_orm/sqflite_orm.dart';
import 'package:test/test.dart';

void main() {
  group('WhereClause', () {
    test('equals creates correct condition', () {
      final where = WhereClause().equals('email', 'test@example.com');
      expect(where.conditions.length, 1);
      expect(where.conditions[0], 'email = ?');
      expect(where.arguments.length, 1);
      expect(where.arguments[0], 'test@example.com');
    });

    test('notEquals creates correct condition', () {
      final where = WhereClause().notEquals('status', 'deleted');
      expect(where.conditions.length, 1);
      expect(where.conditions[0], 'status != ?');
      expect(where.arguments[0], 'deleted');
    });

    test('greaterThan creates correct condition', () {
      final where = WhereClause().greaterThan('age', 18);
      expect(where.conditions[0], 'age > ?');
      expect(where.arguments[0], 18);
    });

    test('lessThan creates correct condition', () {
      final where = WhereClause().lessThan('age', 65);
      expect(where.conditions[0], 'age < ?');
      expect(where.arguments[0], 65);
    });

    test('greaterThanOrEqual creates correct condition', () {
      final where = WhereClause().greaterThanOrEqual('score', 100);
      expect(where.conditions[0], 'score >= ?');
      expect(where.arguments[0], 100);
    });

    test('lessThanOrEqual creates correct condition', () {
      final where = WhereClause().lessThanOrEqual('price', 100.0);
      expect(where.conditions[0], 'price <= ?');
      expect(where.arguments[0], 100.0);
    });

    test('like creates correct condition', () {
      final where = WhereClause().like('name', '%john%');
      expect(where.conditions[0], 'name LIKE ?');
      expect(where.arguments[0], '%john%');
    });

    test('inList creates correct condition', () {
      final where = WhereClause().inList('status', ['active', 'pending']);
      expect(where.conditions[0], 'status IN (?, ?)');
      expect(where.arguments.length, 2);
      expect(where.arguments[0], 'active');
      expect(where.arguments[1], 'pending');
    });

    test('inList with empty list creates false condition', () {
      final where = WhereClause().inList('status', []);
      expect(where.conditions[0], '1 = 0');
      expect(where.arguments.length, 0);
    });

    test('isNull creates correct condition', () {
      final where = WhereClause().isNull('deletedAt');
      expect(where.conditions[0], 'deletedAt IS NULL');
      expect(where.arguments.length, 0);
    });

    test('isNotNull creates correct condition', () {
      final where = WhereClause().isNotNull('email');
      expect(where.conditions[0], 'email IS NOT NULL');
      expect(where.arguments.length, 0);
    });

    test('multiple conditions are combined with AND', () {
      final where = WhereClause()
          .equals('status', 'active')
          .greaterThan('age', 18)
          .isNotNull('email');
      expect(where.conditions.length, 3);
      expect(where.arguments.length, 2);
    });

    test('and combines two where clauses', () {
      final where1 = WhereClause().equals('status', 'active');
      final where2 = WhereClause().greaterThan('age', 18);
      final combined = where1.and(where2);
      expect(combined.conditions.length, 2);
      expect(combined.arguments.length, 2);
    });

    test('or combines two where clauses', () {
      final where1 = WhereClause().equals('status', 'active');
      final where2 = WhereClause().equals('status', 'pending');
      final combined = where1.or(where2);
      expect(combined.conditions.length, 1);
      expect(combined.conditions[0], contains('OR'));
    });

    test('build returns empty string for no conditions', () {
      final where = WhereClause();
      expect(where.build(), '');
    });

    test('build returns correct WHERE clause', () {
      final where = WhereClause()
          .equals('status', 'active')
          .greaterThan('age', 18);
      final sql = where.build();
      expect(sql, contains('WHERE'));
      expect(sql, contains('status = ?'));
      expect(sql, contains('age > ?'));
      expect(sql, contains('AND'));
    });

    test('args getter returns arguments list', () {
      final where = WhereClause()
          .equals('email', 'test@example.com')
          .equals('status', 'active');
      expect(where.args.length, 2);
      expect(where.args[0], 'test@example.com');
      expect(where.args[1], 'active');
    });
  });
}

