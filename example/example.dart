import 'package:sqflite_orm/sqflite_orm.dart';
import 'package:sqflite_common/sqlite_api.dart' show Transaction;

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

  @Column(name: 'age')
  int? age;

  @Column(name: 'active')
  bool? active;

  @Column(name: 'createdAt')
  DateTime? createdAt;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'age': age,
      'active': active == true ? 1 : 0,
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
      ..age = map['age'] as int?
      ..active = (map['active'] as int?) == 1
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

  @Column(name: 'views')
  int? views;

  @Column(name: 'createdAt')
  DateTime? createdAt;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userId': userId,
      'published': published == true ? 1 : 0,
      'views': views,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return Post()
      ..id = map['id'] as int?
      ..title = map['title'] as String?
      ..content = map['content'] as String?
      ..userId = map['userId'] as int?
      ..published = (map['published'] as int?) == 1
      ..views = map['views'] as int?
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null;
  }

  @override
  String get tableName => 'posts';
}

// ============================================
// MAIN APPLICATION
// ============================================

void main() async {
  // Initialize database
  // Note: If you change the schema, increment the version to trigger migrations
  final db = await DatabaseManager.initialize(
    path: 'example.db',
    version:
        2, // Incremented to handle schema changes (added age, views fields)
    models: [User, Post],
    instanceCreators: {
      User: () => User(),
      Post: () => Post(),
    },
    webDebug: true,
    webDebugPort: 4800,
  );

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

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  // Method 1: Create using map (Sequelize Model.create())
  final user1 = await db.query<User>().create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'phone': '+1234567890',
    'age': 30,
    'active': true,
    'createdAt': DateTime.now(),
  });

  // Method 2: Insert using model instance
  final user2 = User()
    ..name = 'Jane Smith'
    ..email = 'jane@example.com'
    ..phone = '+0987654321'
    ..age = 25
    ..active = true
    ..createdAt = DateTime.now();
  final userId2 = await db.query<User>().insert(user2);

  // Method 3: Create multiple records
  final user3 = await db.query<User>().create({
    'name': 'Bob Wilson',
    'email': 'bob@example.com',
    'age': 35,
    'active': false,
    'createdAt': DateTime.now(),
  });

  // Create posts
  final post1 = await db.query<Post>().create({
    'title': 'First Post',
    'content': 'This is my first post!',
    'userId': user1.id,
    'published': true,
    'views': 100,
    'createdAt': DateTime.now(),
  });

  await db.query<Post>().create({
    'title': 'Second Post',
    'content': 'Another post by John',
    'userId': user1.id,
    'published': true,
    'views': 50,
    'createdAt': DateTime.now(),
  });

  await db.query<Post>().create({
    'title': 'Draft Post',
    'content': 'This is a draft',
    'userId': user2.id,
    'published': false,
    'views': 0,
    'createdAt': DateTime.now(),
  });

  // ============================================
  // READ OPERATIONS - Basic Queries
  // ============================================

  // Find all records
  await db.query<User>().findAll();
  await db.query<Post>().findAll();

  // Find first record
  await db.query<User>().findFirst();

  // Find one record (alias for findFirst)
  await db.query<User>().findOne();

  // Find by primary key
  final userById = await db.query<User>().findByPk(user1.id!);

  // ============================================
  // READ OPERATIONS - WHERE Clauses
  // ============================================

  // WHERE with equals
  await db
      .query<User>()
      .whereClause(WhereClause().equals('email', 'john@example.com'))
      .findAll();

  // WHERE with not equals
  await db
      .query<User>()
      .whereClause(WhereClause().notEquals('active', 0))
      .findAll();

  // WHERE with greater than
  await db
      .query<User>()
      .whereClause(WhereClause().greaterThan('age', 25))
      .findAll();

  // WHERE with less than
  await db
      .query<User>()
      .whereClause(WhereClause().lessThan('age', 30))
      .findAll();

  // WHERE with greater than or equal
  await db
      .query<User>()
      .whereClause(WhereClause().greaterThanOrEqual('age', 30))
      .findAll();

  // WHERE with less than or equal
  await db
      .query<User>()
      .whereClause(WhereClause().lessThanOrEqual('age', 25))
      .findAll();

  // WHERE with IS NULL
  await db.query<User>().whereClause(WhereClause().isNull('phone')).findAll();

  // WHERE with IS NOT NULL
  await db
      .query<User>()
      .whereClause(WhereClause().isNotNull('phone'))
      .findAll();

  // WHERE with LIKE
  await db
      .query<User>()
      .whereClause(WhereClause().like('name', '%John%'))
      .findAll();

  // WHERE with IN
  await db
      .query<User>()
      .whereClause(WhereClause().inList('id', [user1.id, user2.id, user3.id]))
      .findAll();

  // WHERE with NOT IN (using NOT equals with OR)
  await db
      .query<User>()
      .whereClause(WhereClause()
          .notEquals('id', user1.id)
          .and(WhereClause().notEquals('id', user2.id)))
      .findAll();

  // WHERE with BETWEEN (using greaterThanOrEqual and lessThanOrEqual)
  await db
      .query<User>()
      .whereClause(WhereClause()
          .greaterThanOrEqual('age', 25)
          .lessThanOrEqual('age', 35))
      .findAll();

  // WHERE with AND (multiple conditions)
  final complexWhere = WhereClause()
      .equals('active', 1)
      .greaterThan('age', 20)
      .isNotNull('email');
  await db.query<User>().whereClause(complexWhere).findAll();

  // WHERE with OR
  final orWhere = WhereClause()
      .equals('name', 'John Doe')
      .or(WhereClause().equals('name', 'Jane Smith'));
  await db.query<User>().whereClause(orWhere).findAll();

  // ============================================
  // READ OPERATIONS - ORDER BY
  // ============================================

  // Order by ascending
  await db.query<User>().orderBy('name').findAll();

  // Order by descending
  await db.query<User>().orderBy('createdAt', descending: true).findAll();

  // Order by multiple columns (chain orderBy)
  await db
      .query<Post>()
      .orderBy('published', descending: true)
      .orderBy('views', descending: true)
      .findAll();

  // ============================================
  // READ OPERATIONS - LIMIT and OFFSET
  // ============================================

  // Limit results
  await db.query<User>().limit(5).findAll();

  // Limit with offset (pagination)
  await db.query<User>().limit(10).offset(0).findAll();
  await db.query<User>().limit(10).offset(10).findAll();
  await db.query<User>().limit(10).offset(20).findAll();
  print('Limit and offset executed successfully');
  // ============================================
  // READ OPERATIONS - SELECT Specific Columns
  // ============================================

  // Select specific columns
  await db.query<User>().select(['id', 'name', 'email']).findAll();

  print('Select specific columns executed successfully');

  // ============================================
  // READ OPERATIONS - COUNT
  // ============================================

  // Count all records
  await db.query<User>().count();

  // Count with WHERE clause
  await db.query<User>().whereClause(WhereClause().equals('active', 1)).count();

  // Count with complex WHERE
  await db
      .query<User>()
      .whereClause(WhereClause().greaterThan('age', 25).isNotNull('phone'))
      .count();

  print('Count operations executed successfully');

  // ============================================
  // ASSOCIATIONS / RELATIONSHIPS - Eager Loading
  // ============================================

  // Example 1: findAll() with include - Posts with authors
  final postsWithAuthors = await db
      .query<Post>()
      .include(['author'])
      .whereClause(WhereClause().equals('published', 1))
      .findAll();
  // Access loaded relationships
  for (final post in postsWithAuthors) {
    post.getRelation<User>('author');
    // Access: post.getRelation<User>('author') returns User?
    // Use: post.getRelation<User>('author')?.name, post.getRelation<User>('author')?.email
  }

  // Example 2: findOne() with include - User with posts
  final userWithPosts =
      await db.query<User>().include(['posts']).findByPk(user1.id!);
  if (userWithPosts != null) {
    userWithPosts.getRelationList<Post>('posts');
    // Access: userWithPosts.getRelationList<Post>('posts') returns List<Post>
  }

  // Example 3: findByPk() with multiple includes - Post with author
  final postWithAuthor =
      await db.query<Post>().include(['author']).findByPk(post1.id!);
  if (postWithAuthor != null) {
    postWithAuthor.getRelation<User>('author');
    // Access: postWithAuthor.getRelation<User>('author') returns User?
  }

  // Example 4: findFirst() with include
  final firstPostWithAuthor =
      await db.query<Post>().include(['author']).findFirst();
  if (firstPostWithAuthor != null) {
    firstPostWithAuthor.getRelation<User>('author');
    // Access: firstPostWithAuthor.getRelation<User>('author') returns User?
  }

  // Example 5: findAll() with include and ORDER BY
  final topPostsWithAuthors = await db
      .query<Post>()
      .include(['author'])
      .orderBy('views', descending: true)
      .limit(5)
      .findAll();
  for (final post in topPostsWithAuthors) {
    post.getRelation<User>('author');
    // Access: post.getRelation<User>('author') returns User?
    // Use: post.title, post.getRelation<User>('author')?.name, post.views
  }

  // Example 6: findAll() with include and WHERE - Published posts with authors
  final publishedPostsWithAuthors = await db
      .query<Post>()
      .include(['author'])
      .whereClause(WhereClause().equals('published', 1))
      .findAll();
  for (final post in publishedPostsWithAuthors) {
    post.getRelation<User>('author');
    // Access: post.getRelation<User>('author') returns User?
    // Use: post.title, post.getRelation<User>('author')?.name
  }

  // Example 7: findAll() with include - Users with their posts
  final usersWithPostsList =
      await db.query<User>().include(['posts']).limit(10).findAll();
  for (final user in usersWithPostsList) {
    user.getRelationList<Post>('posts');
    // Access: user.getRelationList<Post>('posts') returns List<Post>
  }

  // Example 8: findAll() with include and WHERE - Active users with posts
  final activeUsersWithPosts = await db
      .query<User>()
      .include(['posts'])
      .whereClause(WhereClause().equals('active', 1))
      .findAll();
  for (final user in activeUsersWithPosts) {
    user.getRelationList<Post>('posts');
    // Access: user.getRelationList<Post>('posts') returns List<Post>
  }

  // Example 9: Using withRelations() alias (same as include)
  final postsWithRelations =
      await db.query<Post>().withRelations(['author']).findAll();
  for (final post in postsWithRelations) {
    post.getRelation<User>('author');
    // Access: post.getRelation<User>('author') returns User?
  }

  // Example 10: Complex query with include, WHERE, ORDER BY, LIMIT
  final complexPostsWithAuthors = await db
      .query<Post>()
      .include(['author'])
      .whereClause(
          WhereClause().equals('published', 1).greaterThan('views', 50))
      .orderBy('createdAt', descending: true)
      .limit(10)
      .findAll();
  for (final post in complexPostsWithAuthors) {
    post.getRelation<User>('author');
    // Access: post.getRelation<User>('author') returns User?
  }

  print('Complex query executed successfully');

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  // Method 1: Update instance (Sequelize instance.save())
  if (userById != null) {
    userById.name = 'John Updated';
    userById.phone = '+1111111111';
    await db.query<User>().update(userById);
  }

  // Method 2: Update with WHERE clause (Sequelize Model.update())
  final updateWhere = WhereClause().equals('id', userId2);
  await db.query<User>().whereClause(updateWhere).updateValues({
    'email': 'jane.updated@example.com',
    'phone': '+2222222222',
  });

  // Method 3: Update multiple records
  await db
      .query<User>()
      .whereClause(WhereClause().equals('active', 0))
      .updateValues({'active': 1});

  // Method 4: Update with complex WHERE
  await db
      .query<Post>()
      .whereClause(
          WhereClause().equals('published', 1).greaterThan('views', 50))
      .updateValues({'views': 0});

  print('Update operations executed successfully');

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  // Delete with WHERE clause
  await db
      .query<Post>()
      .whereClause(WhereClause().equals('published', 0))
      .delete();

  // Delete with complex WHERE
  await db
      .query<User>()
      .whereClause(WhereClause().equals('active', 0).isNull('email'))
      .delete();

  print('Delete operations executed successfully');

  // ============================================
  // COMPLEX QUERIES - Combinations
  // ============================================

  // Complex query: WHERE + ORDER BY + LIMIT + OFFSET
  await db
      .query<User>()
      .whereClause(WhereClause().equals('active', 1).greaterThan('age', 25))
      .orderBy('createdAt', descending: true)
      .limit(10)
      .offset(0)
      .findAll();

  // Complex query: SELECT + WHERE + ORDER BY
  await db
      .query<Post>()
      .select(['id', 'title', 'views'])
      .whereClause(WhereClause().equals('published', 1))
      .orderBy('views', descending: true)
      .limit(5)
      .findAll();
  print('Complex query executed successfully');
  // Complex query: Include + WHERE + ORDER BY + LIMIT
  await db
      .query<Post>()
      .include(['author'])
      .whereClause(WhereClause().equals('published', 1))
      .orderBy('createdAt', descending: true)
      .limit(10)
      .findAll();

  print('Complex query executed successfully');
  // ============================================
  // TRANSACTIONS
  // ============================================

  try {
    await db.transaction((Transaction txn) async {
      // Create multiple users in a transaction
      final user4 = User()
        ..name = 'Transaction User 1'
        ..email = 'tx1@example.com'
        ..active = true;

      final user5 = User()
        ..name = 'Transaction User 2'
        ..email = 'tx2@example.com'
        ..active = true;

      // Use transaction object for all database operations
      await db.queryWithTransaction<User>(txn).insert(user4);
      await db.queryWithTransaction<User>(txn).insert(user5);

      // If an error occurs, the transaction will rollback automatically
      print('Transaction successful');
    });
  } catch (e) {
    // Transaction failed
  }

  // ============================================
  // RAW QUERIES (when needed)
  // ============================================

  // Raw query example
  await db.database.rawQuery(
    'SELECT * FROM users WHERE age > ? AND active = ?',
    [25, 1],
  );

  // Raw update example
  await db.database.rawUpdate(
    'UPDATE posts SET views = views + 1 WHERE id = ?',
    [post1.id],
  );

  // Raw delete example
  await db.database.rawDelete(
    'DELETE FROM users WHERE id = ?',
    [user3.id],
  );
  print('Successfully executed all operations');
  // Close database connection
  await db.close();
}
