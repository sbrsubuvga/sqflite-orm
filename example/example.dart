import 'package:sqflite_orm/sqflite_orm.dart';

// ============================================
// MODEL DEFINITIONS
// ============================================

/// User model
@Table(name: 'users')
class User extends BaseModel {
  @PrimaryKey()
  @Column(name: 'id')
  int? id;

  @Column(name: 'name')
  String? name;

  @Column(name: 'email')
  String? email;

  @Column(name: 'phone')
  String? phone;

  @Column(name: 'createdAt')
  DateTime? createdAt;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return User()
      ..id = map['id'] as int?
      ..name = map['name'] as String?
      ..email = map['email'] as String?
      ..phone = map['phone'] as String?
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null;
  }

  @override
  String get tableName => 'users';
}

/// Post model
@Table(name: 'posts')
class Post extends BaseModel {
  @PrimaryKey()
  @Column(name: 'id')
  int? id;

  @Column(name: 'title')
  String? title;

  @Column(name: 'content')
  String? content;

  @Column(name: 'userId')
  int? userId;

  @Column(name: 'published')
  bool? published;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userId': userId,
      'published': published == true ? 1 : 0,
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return Post()
      ..id = map['id'] as int?
      ..title = map['title'] as String?
      ..content = map['content'] as String?
      ..userId = map['userId'] as int?
      ..published = (map['published'] as int?) == 1;
  }

  @override
  String get tableName => 'posts';
}

// ============================================
// MAIN APPLICATION
// ============================================

void main() async {
  print('=== SQLite ORM Example (Pure Dart) ===\n');

  // Initialize database
  // Note: sqflite_common_ffi is used for all platforms (works everywhere via FFI)
  final db = await DatabaseManager.initialize(
    path: 'example.db',
    version: 1,
    models: [User, Post],
    instanceCreators: {
      User: () => User(),
      Post: () => Post(),
    },
    webDebug: true,
    webDebugPort: 4800,
  );

  print('✓ Database initialized\n');

  // Register relationships
  final registry = ModelRegistry();
  final postInfo = registry.getInfo(Post);
  if (postInfo != null) {
    final updatedPostInfo = ModelInfo(
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
      },
      factory: postInfo.factory,
    );
    registry.register(Post, updatedPostInfo);
  }

  final userInfo = registry.getInfo(User);
  if (userInfo != null) {
    final updatedUserInfo = ModelInfo(
      tableName: userInfo.tableName,
      modelType: userInfo.modelType,
      columns: userInfo.columns,
      primaryKey: userInfo.primaryKey,
      foreignKeys: userInfo.foreignKeys,
      relationships: {
        'posts': RelationshipInfo(
          type: 'OneToMany',
          targetType: Post,
          foreignKey: 'userId',
        ),
      },
      factory: userInfo.factory,
    );
    registry.register(User, updatedUserInfo);
  }

  // Create a user
  print('Creating user...');
  final user = await db.query<User>().create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'phone': '+1234567890',
    'createdAt': DateTime.now(),
  });
  print('✓ Created user: ${user.name} (ID: ${user.id})\n');

  // Create a post
  print('Creating post...');
  final post = await db.query<Post>().create({
    'title': 'My First Post',
    'content': 'This is a sample post created from a pure Dart script!',
    'userId': user.id,
    'published': true,
  });
  print('✓ Created post: ${post.title} (ID: ${post.id})\n');

  // Query with include (eager loading)
  print('Querying posts with author (eager loading)...');
  final posts = await db.query<Post>().include(['author']).findAll();
  for (final p in posts) {
    final author = p.getRelation<User>('author');
    print('  - ${p.title} by ${author?.name ?? 'Unknown'}');
  }
  print('');

  // Find all users
  print('All users:');
  final users = await db.query<User>().findAll();
  for (final u in users) {
    print('  - ${u.name} (${u.email})');
  }
  print('');

  // Find all posts
  print('All posts:');
  final allPosts = await db.query<Post>().findAll();
  for (final p in allPosts) {
    print('  - ${p.title}');
  }
  print('');

  print('=== Example completed ===');
  print('Web UI available at: http://localhost:4800');
  print('Press Ctrl+C to exit\n');

  // Keep the process alive
  try {
    await Future.delayed(const Duration(days: 1));
  } catch (e) {
    await db.close();
  }
}
