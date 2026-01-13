# SQLite ORM

A comprehensive Dart SQLite ORM package with cross-platform support (desktop, mobile, web), automatic migrations, relationship handling, query builder, and a web-based database management UI.

## Features

- **Cross-Platform**: Works everywhere - pure Dart (no Flutter SDK required)
- **FFI-Based**: Uses `sqflite_common_ffi` for all platforms (works via Foreign Function Interface)
- **Type-Safe ORM**: Strong typing with Dart generics
- **Simplified Registration**: Automatic column inference from models - no boilerplate needed
- **Runtime Validation**: Schema mismatch detection at runtime
- **Automatic Migrations**: Generate migrations from model changes
- **Associations**: Full support for eager loading with `include()` (Sequelize-style)
- **Query Builder**: Fluent, type-safe query API with `findAll()`, `findOne()`, `findByPk()`
- **CRUD Operations**: `create()`, `insert()`, `update()`, `delete()` methods
- **Web UI**: Full-featured database management interface with pagination and table browser
- **Web Debug Mode**: Automatically start Web UI during development
- **Transactions**: Full transaction support with rollback

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sqflite_orm: ^0.1.18
```

### Platform Support

`sqflite_orm` uses `sqflite_common_ffi` for all platforms, which works everywhere via FFI:

```yaml
dependencies:
  sqflite_orm: ^0.1.18
  # No additional dependencies needed - works on all platforms
```

**How it works:**
- **All platforms (Desktop, Mobile, Web)**: Uses `sqflite_common_ffi` (FFI-based)
- **Desktop (Windows/Linux/macOS)**: Uses `sqflite_common_ffi` (FFI-based)
- **Mobile (Android/iOS)**: Uses `sqflite_common_ffi` (FFI works on mobile too)
- **Pure Dart packages**: Always uses `sqflite_common_ffi` for all platforms

**Note:** This is a pure Dart package - no Flutter SDK required. The package uses `sqflite_common_ffi` which works on all platforms via FFI (Foreign Function Interface). This means:
- ✅ Works with pure Dart (no Flutter SDK required)
- ✅ Works on all platforms: Desktop, Mobile, and Web
- ✅ No platform-specific setup needed
- ✅ Consistent behavior across all platforms

## Architecture & Platform Support

`sqflite_orm` uses **conditional imports** to automatically select the best SQLite implementation for each platform:

### Platform Selection Logic

```
┌─────────────────────────────────────────────────────────┐
│ Platform Detection                                      │
├─────────────────────────────────────────────────────────┤
│ Desktop (Windows/Linux/macOS)                           │
│   → Always uses sqflite_common_ffi (FFI-based)         │
│                                                          │
│ Mobile (Android/iOS)                                     │
│   ├─ Flutter app WITH sqflite                           │
│   │   → Uses sqflite (native plugin, recommended)       │
│   ├─ Flutter app WITHOUT sqflite                        │
│   │   → Falls back to sqflite_common_ffi (FFI works)   │
│   └─ Pure Dart                                           │
│       → Always uses sqflite_common_ffi (FFI works)      │
└─────────────────────────────────────────────────────────┘
```

### Why This Design?

- **`sqflite`** → Android/iOS only (requires Flutter SDK)
- **`sqflite_common_ffi`** → Desktop/CI/Tests (works everywhere via FFI)
- **`sqflite_orm`** → Works everywhere (uses conditional imports internally)

This design allows:
- ✅ Pure Dart packages to use the ORM without Flutter
- ✅ Flutter apps to get native performance on mobile (if sqflite is added)
- ✅ Desktop apps to work out of the box
- ✅ CI/CD pipelines to run tests without Flutter SDK
- ✅ `dart pub` analysis to pass (no Flutter-only dependencies)

### SQLite Implementation

| Implementation | Platforms | Requires Flutter | Performance |
|---------------|-----------|------------------|-------------|
| `sqflite_common_ffi` | All (Desktop, Mobile, Web) | ❌ No | ⭐⭐⭐⭐ FFI |

## Quick Start

### 1. Define Your Models

```dart
import 'package:sqflite_orm/sqflite_orm.dart';

@Table(name: 'users')
class User extends BaseModel {
  @PrimaryKey()
  @Column(name: 'id')
  int? id;
  
  @Column(name: 'name')
  String? name;
  
  @Column(name: 'email')
  String? email;
  
  @Column(name: 'createdAt')
  DateTime? createdAt;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return User()
      ..id = map['id'] as int?
      ..name = map['name'] as String?
      ..email = map['email'] as String?
      ..createdAt = map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null;
  }

  @override
  String get tableName => 'users';
}
```

### 2. Initialize Database

```dart
final db = await DatabaseManager.initialize(
  path: 'app.db',
  version: 1,
  models: [User, Post, Comment],
  instanceCreators: {
    User: () => User(),
    Post: () => Post(),
    Comment: () => Comment(),
  },
  // Optional: Enable Web UI for development
  webDebug: true,
  webDebugPort: 4800,
);
```

**Note**: Platform detection and SQLite initialization are handled automatically. The package uses `sqflite_common_ffi` for all platforms:
- Works on Desktop, Mobile, and Web
- No manual setup needed!
- Consistent behavior across all platforms

### 3. CRUD Operations

#### Create Records

```dart
// Method 1: Using create() - returns model instance
final user = await db.query<User>().create({
  'name': 'John Doe',
  'email': 'john@example.com',
  'createdAt': DateTime.now(),
});
print('Created user: ${user.name} (ID: ${user.id})');

// Method 2: Using insert() - returns inserted ID
final user = User()
  ..name = 'Jane Smith'
  ..email = 'jane@example.com';
final id = await db.query<User>().insert(user);
```

#### Read Records

```dart
// Find all records
final users = await db.query<User>().findAll();

// Find one record
final user = await db.query<User>().findOne();

// Find by primary key
final user = await db.query<User>().findByPk(123);

// Find with conditions
final users = await db.query<User>()
  .whereClause(WhereClause().equals('email', 'john@example.com'))
  .findAll();

// Find with ordering and pagination
final users = await db.query<User>()
  .orderBy('createdAt', descending: true)
  .limit(10)
  .offset(0)
  .findAll();

// Count records
final count = await db.query<User>()
  .whereClause(WhereClause().equals('active', true))
  .count();
```

#### Update Records

```dart
// Update using model instance
final user = await db.query<User>().findByPk(123);
if (user != null) {
  user.name = 'Updated Name';
  await db.query<User>().update(user);
}

// Update using values map
final rowsUpdated = await db.query<User>()
  .whereClause(WhereClause().equals('id', 123))
  .updateValues({'name': 'Updated Name'});
```

#### Delete Records

```dart
// Delete with conditions
final rowsDeleted = await db.query<User>()
  .whereClause(WhereClause().equals('id', 123))
  .delete();
```

### 4. Associations (Eager Loading)

Register relationships and use `include()` for eager loading, similar to Sequelize:

```dart
// Register relationships (after database initialization)
final registry = ModelRegistry();
final postInfo = registry.getInfo(Post);
if (postInfo != null) {
  final updatedInfo = ModelInfo(
    tableName: postInfo.tableName,
    modelType: postInfo.modelType,
    columns: postInfo.columns,
    primaryKey: postInfo.primaryKey,
    foreignKeys: postInfo.foreignKeys,
    relationships: {
      'author': RelationshipInfo(
        type: 'ManyToOne',
        targetType: User,
        foreignKey: 'userId',
      ),
      'comments': RelationshipInfo(
        type: 'OneToMany',
        targetType: Comment,
        foreignKey: 'postId',
      ),
    },
    factory: postInfo.factory,
  );
  registry.register(Post, updatedInfo);
}

// Use include() for eager loading
final post = await db.query<Post>()
  .include(['author', 'comments'])
  .findByPk(1);

// Access loaded relationships
final author = post?.getRelation<User>('author');
final comments = post?.getRelationList<Comment>('comments') ?? [];

// findAll() with include
final posts = await db.query<Post>()
  .include(['author'])
  .findAll();

// findOne() with include
final user = await db.query<User>()
  .include(['posts'])
  .findOne();
```

### 5. Transactions

```dart
// Use queryWithTransaction() inside transactions
await db.transaction((txn) async {
  final user1 = await db.queryWithTransaction<User>(txn).create({
    'name': 'User 1',
    'email': 'user1@example.com',
  });
  
  final user2 = await db.queryWithTransaction<User>(txn).create({
    'name': 'User 2',
    'email': 'user2@example.com',
  });
  
  // If any operation fails, transaction is rolled back automatically
});
```

### 6. Web Debug Mode

Enable Web UI automatically during development:

```dart
final db = await DatabaseManager.initialize(
  path: 'app.db',
  version: 1,
  models: [User, Post],
  instanceCreators: {
    User: () => User(),
    Post: () => Post(),
  },
  // Automatically start Web UI
  webDebug: true,
  webDebugPort: 4800,
  // webDebugPassword: 'secret', // Note: sqflite_dev does not support password protection
);
```

When the Web UI starts, you'll see output like:

```
✓ Web UI server started
  Local:   http://localhost:4800
  Network: http://192.168.1.100:4800
  (Access from your PC using the Network URL above)
```

**Accessing from PC when debugging on Android:**

When debugging your Flutter app on an Android device, the Web UI server automatically:
- Binds to all network interfaces (0.0.0.0) to allow network access
- Detects and displays your device's local IP address
- Provides both Local and Network URLs

**To access from your PC:**
1. Ensure both your PC and Android device are on the same Wi‑Fi network
2. Use the **Network URL** shown in the console output (e.g., `http://192.168.1.100:4800`)
3. Open this URL in your PC's browser to access the Web UI

**Note:** The Local URL (`http://localhost:4800`) works when running on emulators or when accessing from the device itself.

## Web UI Features

The web UI provides a modern interface for database management:

![Web UI Screenshot](https://raw.githubusercontent.com/sbrsubuvga/sqflite-orm/refs/heads/main/Screenshot%202026-01-12%20at%208.15.40%E2%80%AFPM.png)

- **Table Browser**: Left sidebar listing all database tables
- **Data Grid**: Browse and view table data with pagination
- **Pagination**: Configurable page size (10, 25, 50, 100, 200 rows)
- **SQL Query Editor**: Execute custom SQL queries
- **Schema Viewer**: View table structure and column information
- **Network Access**: Access from your PC when debugging on Android devices
- **Cross-Platform**: Works in both Flutter and pure Dart environments

### Accessing the Web UI

**Local Access (Emulator/Desktop):**
- Access at `http://localhost:4800` (or your configured port)

**Network Access (Android Device):**
- When debugging on an Android device, the server automatically detects and displays your device's IP address
- Use the Network URL shown in the console (e.g., `http://192.168.1.100:4800`) from your PC's browser
- Both devices must be on the same Wi‑Fi network

## Query Builder API

### Find Methods

```dart
// Find all
final users = await db.query<User>().findAll();

// Find first
final user = await db.query<User>().findFirst();

// Find one (alias for findFirst)
final user = await db.query<User>().findOne();

// Find by primary key
final user = await db.query<User>().findByPk(123);
```

### Where Clauses

```dart
// Equals
.whereClause(WhereClause().equals('email', 'john@example.com'))

// Greater than
.whereClause(WhereClause().greaterThan('age', 18))

// Less than
.whereClause(WhereClause().lessThan('age', 65))

// Multiple conditions
.whereClause(WhereClause()
  .equals('status', 'active')
  .greaterThan('createdAt', DateTime(2024, 1, 1)))
```

### Ordering and Pagination

```dart
.orderBy('createdAt', descending: true)
.limit(10)
.offset(20)
```

### Associations

```dart
.include(['author', 'comments', 'tags'])
```

## Annotations

### @Table
Marks a class as a database table.

```dart
@Table(name: 'users')
class User extends BaseModel { ... }
```

### @Column
Marks a field as a database column.

```dart
@Column(name: 'email')
String? email;
```

### @PrimaryKey
Marks a field as a primary key.

```dart
@PrimaryKey()
@Column(name: 'id')
int? id;
```

### @ForeignKey
Marks a field as a foreign key.

```dart
@ForeignKey(table: 'users', column: 'id')
@Column(name: 'userId')
int? userId;
```

## Migrations

Migrations are handled automatically. When you change your models and increment the version number, the package will:

1. Detect new tables
2. Create missing tables
3. Add missing columns to existing tables
4. Validate schema changes

For complex migrations, you can provide a custom `onUpgrade` callback:

```dart
final db = await DatabaseManager.initialize(
  path: 'app.db',
  version: 2,
  models: [User, Post],
  instanceCreators: {
    User: () => User(),
    Post: () => Post(),
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      // Custom migration logic
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
  },
);
```

## Complete Example

See `example/example.dart` for a comprehensive example including:

- Model definitions
- CRUD operations
- Associations and eager loading
- Transactions
- Complex queries
- Web UI integration

Run the example:

```bash
cd example
dart run example.dart
```

The example will:
- Create a database
- Create sample users and posts
- Demonstrate CRUD operations
- Show eager loading with `include()`
- Start a Web UI at http://localhost:4800

## Running Tests

The package includes comprehensive unit tests covering core functionality.

### Quick Start

```bash
# Run all tests
dart test
```

### Running Specific Tests

```bash
# Run a specific test file
dart test test/where_clause_test.dart
```

## Real-World Examples

### Finzo - Income & Expense Management App

[**Finzo**](https://github.com/sbrsubuvga/finzo) is a real-world Flutter application that demonstrates the use of `sqflite_orm` in production. It's an income and expense management app that showcases:

- Complex model relationships
- Transaction handling for financial operations
- Data persistence and management
- Cross-platform compatibility (Android, iOS, Desktop, Web)

Check out the [Finzo repository](https://github.com/sbrsubuvga/finzo) to see how `sqflite_orm` is used in a complete application.

## API Reference

### DatabaseManager

```dart
static Future<DatabaseManager> initialize({
  required String path,
  required int version,
  required List<Type> models,
  Map<Type, BaseModel Function()>? instanceCreators,
  Database? Function(Database db, int oldVersion, int newVersion)? onUpgrade,
  Database? Function(Database db, int version)? onCreate,
  bool webDebug = false,
  int webDebugPort = 4800,
  String? webDebugPassword,
})
```

### QueryBuilder

```dart
// Query methods
Future<List<T>> findAll()
Future<T?> findFirst()
Future<T?> findOne()
Future<T?> findByPk(dynamic primaryKeyValue)
Future<int> count()
Future<int> delete()

// CRUD methods
Future<T> create(Map<String, dynamic> values)
Future<int> insert(T model)
Future<int> update(T model)
Future<int> updateValues(Map<String, dynamic> values)

// Query building
QueryBuilder<T> whereClause(WhereClause clause)
QueryBuilder<T> orderBy(String column, {bool descending = false})
QueryBuilder<T> limit(int count)
QueryBuilder<T> offset(int count)
QueryBuilder<T> include(List<String> associations)
QueryBuilder<T> select(List<String> columns)

// Transactions
QueryBuilder<T> queryWithTransaction(Transaction txn)
```

## License

MIT
