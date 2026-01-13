import 'package:sqflite_orm/sqflite_orm.dart';
import 'package:test/test.dart';

// Test model for registry tests
class TestModel extends BaseModel {
  int? id;
  String? name;

  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  @override
  BaseModel fromMap(Map<String, dynamic> map) =>
      TestModel()
        ..id = map['id'] as int?
        ..name = map['name'] as String?;

  @override
  String get tableName => 'test_models';
}

void main() {
  group('ModelRegistry', () {
    late ModelRegistry registry;

    setUp(() {
      registry = ModelRegistry();
      registry.clear(); // Clear any existing registrations
    });

    tearDown(() {
      registry.clear();
    });

    test('register stores model info', () {
      final info = ModelInfo(
        tableName: 'test_models',
        modelType: TestModel,
        columns: {
          'id': ColumnInfo(
            name: 'id',
            dartType: 'int',
            sqlType: 'INTEGER',
            isPrimaryKey: true,
          ),
          'name': ColumnInfo(
            name: 'name',
            dartType: 'String',
            sqlType: 'TEXT',
          ),
        },
        primaryKey: 'id',
      );

      registry.register<TestModel>(TestModel, info);
      final retrieved = registry.getInfo(TestModel);
      expect(retrieved, isNotNull);
      expect(retrieved!.tableName, 'test_models');
      expect(retrieved.modelType, TestModel);
    });

    test('getInfo returns null for unregistered model', () {
      final info = registry.getInfo(TestModel);
      expect(info, isNull);
    });

    test('getInfo returns correct info for registered model', () {
      final info = ModelInfo(
        tableName: 'test_models',
        modelType: TestModel,
        columns: {
          'id': ColumnInfo(
            name: 'id',
            dartType: 'int',
            sqlType: 'INTEGER',
            isPrimaryKey: true,
          ),
        },
        primaryKey: 'id',
      );

      registry.register<TestModel>(TestModel, info);
      final retrieved = registry.getInfo(TestModel);
      expect(retrieved, equals(info));
    });

    test('allModels returns unmodifiable map', () {
      final info = ModelInfo(
        tableName: 'test_models',
        modelType: TestModel,
        columns: {
          'id': ColumnInfo(
            name: 'id',
            dartType: 'int',
            sqlType: 'INTEGER',
            isPrimaryKey: true,
          ),
        },
        primaryKey: 'id',
      );

      registry.register<TestModel>(TestModel, info);
      final allModels = registry.allModels;
      expect(allModels.length, 1);
      expect(() => allModels.clear(), throwsA(isA<UnsupportedError>()));
    });

    test('clear removes all registrations', () {
      final info = ModelInfo(
        tableName: 'test_models',
        modelType: TestModel,
        columns: {
          'id': ColumnInfo(
            name: 'id',
            dartType: 'int',
            sqlType: 'INTEGER',
            isPrimaryKey: true,
          ),
        },
        primaryKey: 'id',
      );

      registry.register<TestModel>(TestModel, info);
      expect(registry.getInfo(TestModel), isNotNull);
      registry.clear();
      expect(registry.getInfo(TestModel), isNull);
    });

    test('registry is singleton', () {
      final registry1 = ModelRegistry();
      final registry2 = ModelRegistry();
      expect(identical(registry1, registry2), isTrue);
    });
  });

  group('ModelInfo', () {
    test('creates model info with all fields', () {
      final columns = {
        'id': ColumnInfo(
          name: 'id',
          dartType: 'int',
          sqlType: 'INTEGER',
          isPrimaryKey: true,
        ),
        'name': ColumnInfo(
          name: 'name',
          dartType: 'String',
          sqlType: 'TEXT',
        ),
      };

      final foreignKeys = {
        'userId': ForeignKeyInfo(
          table: 'users',
          column: 'id',
        ),
      };

      final relationships = {
        'posts': RelationshipInfo(
          type: 'OneToMany',
          targetType: TestModel,
          foreignKey: 'userId',
        ),
      };

      BaseModel factory(Map<String, dynamic> map) => TestModel().fromMap(map);

      final info = ModelInfo(
        tableName: 'test_models',
        modelType: TestModel,
        columns: columns,
        primaryKey: 'id',
        foreignKeys: foreignKeys,
        relationships: relationships,
        factory: factory,
      );

      expect(info.tableName, 'test_models');
      expect(info.modelType, TestModel);
      expect(info.columns, columns);
      expect(info.primaryKey, 'id');
      expect(info.foreignKeys, foreignKeys);
      expect(info.relationships, relationships);
      expect(info.factory, factory);
    });
  });

  group('ColumnInfo', () {
    test('creates column info with all fields', () {
      final info = ColumnInfo(
        name: 'id',
        dartType: 'int',
        sqlType: 'INTEGER',
        nullable: false,
        defaultValue: '0',
        isPrimaryKey: true,
        autoIncrement: true,
      );

      expect(info.name, 'id');
      expect(info.dartType, 'int');
      expect(info.sqlType, 'INTEGER');
      expect(info.nullable, false);
      expect(info.defaultValue, '0');
      expect(info.isPrimaryKey, true);
      expect(info.autoIncrement, true);
    });

    test('creates column info with defaults', () {
      final info = ColumnInfo(
        name: 'name',
        dartType: 'String',
        sqlType: 'TEXT',
      );

      expect(info.nullable, true);
      expect(info.defaultValue, isNull);
      expect(info.isPrimaryKey, false);
      expect(info.autoIncrement, false);
    });
  });

  group('ForeignKeyInfo', () {
    test('creates foreign key info', () {
      final info = ForeignKeyInfo(
        table: 'users',
        column: 'id',
        onDeleteCascade: true,
        onUpdateCascade: false,
      );

      expect(info.table, 'users');
      expect(info.column, 'id');
      expect(info.onDeleteCascade, true);
      expect(info.onUpdateCascade, false);
    });

    test('creates foreign key info with defaults', () {
      final info = ForeignKeyInfo(
        table: 'users',
        column: 'id',
      );

      expect(info.onDeleteCascade, false);
      expect(info.onUpdateCascade, false);
    });
  });

  group('RelationshipInfo', () {
    test('creates OneToMany relationship info', () {
      final info = RelationshipInfo(
        type: 'OneToMany',
        targetType: TestModel,
        foreignKey: 'userId',
      );

      expect(info.type, 'OneToMany');
      expect(info.targetType, TestModel);
      expect(info.foreignKey, 'userId');
      expect(info.joinTable, isNull);
    });

    test('creates ManyToMany relationship info', () {
      final info = RelationshipInfo(
        type: 'ManyToMany',
        targetType: TestModel,
        joinTable: 'post_tags',
        thisForeignKey: 'postId',
        targetForeignKey: 'tagId',
      );

      expect(info.type, 'ManyToMany');
      expect(info.targetType, TestModel);
      expect(info.joinTable, 'post_tags');
      expect(info.thisForeignKey, 'postId');
      expect(info.targetForeignKey, 'tagId');
    });
  });
}

