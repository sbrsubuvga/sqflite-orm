# SQLite ORM

A comprehensive Flutter/Dart SQLite ORM package with cross-platform support (desktop, Android, iOS), automatic migrations, relationship handling, query builder, and a web-based database management UI.

## Features

- **Cross-Platform**: Automatic detection and initialization for desktop (Windows, Linux, macOS) and mobile (Android, iOS)
- **Type-Safe ORM**: Strong typing with Dart generics
- **Runtime Validation**: Schema mismatch detection at runtime
- **Automatic Migrations**: Generate migrations from model changes
- **Relationships**: Full support for SQLite-compatible relationships (OneToMany, ManyToOne, ManyToMany)
- **Query Builder**: Fluent, type-safe query API
- **Web UI**: Full-featured database management interface accessible at localhost:4800
- **Transactions**: Full transaction support with rollback

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sqflite_orm: ^0.1.0
```

## Usage

### 1. Define Your Models

```dart
import 'package:sqflite_orm/sqflite_orm.dart';

@Table(name: 'salesData')
class SalesData extends BaseModel {
  @PrimaryKey()
  @Column(name: 'ID')
  int? id;
  
  @Column(name: 'NO')
  int? no;
  
  @Column(name: 'SDate', defaultValue: 'CURRENT_TIMESTAMP')
  DateTime? sDate;
  
  @Column(name: 'GrandAmount')
  double? grandAmount;
  
  @ManyToOne(targetType: CustomerData, foreignKey: 'Customer_Id')
  CustomerData? customer;

  @override
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'NO': no,
      'SDate': sDate?.toIso8601String(),
      'GrandAmount': grandAmount,
      'Customer_Id': customer?.id,
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return SalesData()
      ..id = map['ID'] as int?
      ..no = map['NO'] as int?
      ..sDate = map['SDate'] != null ? DateTime.parse(map['SDate']) : null
      ..grandAmount = map['GrandAmount'] as double?
      ..customer = map['Customer_Id'] != null 
          ? CustomerData()..id = map['Customer_Id'] as int
          : null;
  }

  @override
  String get tableName => 'salesData';
}
```

### 2. Register Models

Before using models, you must register them:

```dart
SimpleModelRegistrar.register<SalesData>(
  tableName: 'salesData',
  columns: {
    'ID': SimpleModelRegistrar.column(
      name: 'ID',
      sqlType: 'INTEGER',
      nullable: false,
      isPrimaryKey: true,
      autoIncrement: true,
    ),
    'NO': SimpleModelRegistrar.column(
      name: 'NO',
      sqlType: 'INTEGER',
      nullable: true,
    ),
    // ... more columns
  },
  primaryKey: 'ID',
);
```

### 3. Initialize Database

```dart
// For Flutter apps
final db = await DatabaseManager.initialize(
  path: 'app.db',
  version: 1,
  models: [SalesData, CustomerData, OrderData],
);

// For pure Dart (desktop)
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'dart:io';

if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  ffi.sqfliteFfiInit();
  databaseFactory = ffi.databaseFactoryFfiNoIsolate;
}

final db = await DatabaseManager.initialize(
  path: 'app.db',
  version: 1,
  models: [SalesData, CustomerData, OrderData],
);
```

### 4. Use Query Builder

```dart
// Find all sales with amount greater than 1000
final sales = await db.query<SalesData>()
  .whereClause(WhereClause().greaterThan('GrandAmount', 1000))
  .orderBy('SDate', descending: true)
  .limit(10)
  .findAll();

// Find first record
final firstSale = await db.query<SalesData>().findFirst();

// Count records
final count = await db.query<SalesData>()
  .whereClause(WhereClause().equals('Customer_Id', 123))
  .count();
```

### 5. Start Web UI

```dart
import 'package:sqflite_orm/web_ui.dart';

// Start web UI server
await WebUI.start(
  db.database,
  port: 4800,
  password: 'dev123', // Optional
);

// Access at http://localhost:4800
// If password is set, use: http://localhost:4800?password=dev123
```

### 6. Use Transactions

```dart
await db.transaction((txn) async {
  // Your database operations here
  await txn.insert('salesData', data1);
  await txn.insert('salesData', data2);
  // If any operation fails, transaction is rolled back automatically
});
```

## Web UI Features

The web UI provides:

- **Table Browser**: View all tables in your database
- **Data Grid**: Browse and view table data with pagination
- **SQL Query Editor**: Execute custom SQL queries
- **Schema Viewer**: View table structure and column information

Access the web UI at `http://localhost:4800` (or your configured port).

## Annotations

### @Table
Marks a class as a database table.

```dart
@Table(name: 'salesData')
class SalesData extends BaseModel { ... }
```

### @Column
Marks a field as a database column.

```dart
@Column(name: 'NO', nullable: true)
int? no;
```

### @PrimaryKey
Marks a field as a primary key.

```dart
@PrimaryKey()
@Column(name: 'ID')
int? id;
```

### @ForeignKey
Marks a field as a foreign key.

```dart
@ForeignKey(table: 'customerData', column: 'Customer_ID')
@Column(name: 'Customer_Id')
int? customerId;
```

### @OneToMany, @ManyToOne, @ManyToMany
Define relationships between models.

```dart
@OneToMany(targetType: OrderItem, foreignKey: 'Order_Id')
List<OrderItem>? items;

@ManyToOne(targetType: CustomerData, foreignKey: 'Customer_Id')
CustomerData? customer;
```

## Schema Validation

The package automatically validates your database schema against model definitions at runtime. If there are mismatches (extra columns, missing columns, type mismatches), warnings or errors will be shown.

## Migrations

Migrations are handled automatically. When you change your models and increment the version number, the package will:

1. Detect new columns
2. Add missing columns to existing tables
3. Validate schema changes

For complex migrations, you can provide a custom `onUpgrade` callback:

```dart
final db = await DatabaseManager.initialize(
  path: 'app.db',
  version: 2,
  models: [SalesData, CustomerData],
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE salesData ADD COLUMN newField TEXT');
    }
  },
);
```

## Running the Example

### For Flutter Apps
The example works directly in Flutter apps.

### For Pure Dart (Desktop)
Run the example with:

```bash
dart run example/example.dart
```

**Note**: For pure Dart execution, make sure you're on a desktop platform (Windows, Linux, macOS) and have initialized FFI:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'dart:io';

if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  ffi.sqfliteFfiInit();
  databaseFactory = ffi.databaseFactoryFfiNoIsolate;
}
```

## License

MIT
