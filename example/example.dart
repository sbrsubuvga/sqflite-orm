import 'package:sqflite_orm/sqflite_orm.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database, Transaction;

// ============================================
// MODEL DEFINITIONS
// ============================================

/// User model - Version 1 (basic fields)
@Table(name: 'users')
class User extends BaseModel {
  @PrimaryKey()
  @Column(name: 'id')
  int? id;

  @Column(name: 'name')
  String? name;

  @Column(name: 'email')
  String? email;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      // Version 2 fields (added in migration)
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

  // Version 2 fields (added via migration)
  @Column(name: 'phone')
  String? phone;

  @Column(name: 'createdAt')
  DateTime? createdAt;
}

/// Post model - demonstrates relationships
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
  int? userId; // Foreign key to User

  @Column(name: 'published')
  bool? published;

  // Relationship: Many-to-One (Post belongs to User)
  // @ManyToOne(targetType: User, foreignKey: 'userId')
  // User? author;

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

/// Comment model - demonstrates One-to-Many and Many-to-One
@Table(name: 'comments')
class Comment extends BaseModel {
  @PrimaryKey()
  @Column(name: 'id')
  int? id;

  @Column(name: 'content')
  String? content;

  @Column(name: 'postId')
  int? postId; // Foreign key to Post

  @Column(name: 'userId')
  int? userId; // Foreign key to User

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'postId': postId,
      'userId': userId,
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return Comment()
      ..id = map['id'] as int?
      ..content = map['content'] as String?
      ..postId = map['postId'] as int?
      ..userId = map['userId'] as int?;
  }

  @override
  String get tableName => 'comments';
}

/// Tag model - demonstrates Many-to-Many
@Table(name: 'tags')
class Tag extends BaseModel {
  @PrimaryKey()
  @Column(name: 'id')
  int? id;

  @Column(name: 'name')
  String? name;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  BaseModel fromMap(Map<String, dynamic> map) {
    return Tag()
      ..id = map['id'] as int?
      ..name = map['name'] as String?;
  }

  @override
  String get tableName => 'tags';
}

// ============================================
// MAIN APPLICATION
// ============================================

void main() async {
  print('🚀 Starting sqflite_orm Example\n');

  // ============================================
  // DATABASE INITIALIZATION WITH MIGRATIONS
  // ============================================

  // Version 1: Initial schema with basic User model
  // Version 2: Add phone and createdAt to User, add Post, Comment, Tag models
  final db = await DatabaseManager.initialize(
    path: 'example.db',
    version: 2, // Start with version 2 to demonstrate migrations
    models: [User, Post, Comment, Tag],
    instanceCreators: {
      User: () => User(),
      Post: () => Post(),
      Comment: () => Comment(),
      Tag: () => Tag(),
    },
    // Custom onCreate callback (called when database is first created)
    onCreate: (Database db, int version) {
      print('📦 Creating database schema (version $version)');
      // Additional setup can be done here
      // Note: For async operations, use .then() or handle them synchronously
      return null;
    },
    // Custom onUpgrade callback (called when version changes)
    onUpgrade: (Database db, int oldVersion, int newVersion) {
      print('🔄 Migrating database from version $oldVersion to $newVersion');

      // Manual migration example
      if (oldVersion < 2) {
        print('  → Adding phone and createdAt columns to users table');
        // These will be added automatically by MigrationManager,
        // but you can add custom migration logic here
        db.execute('ALTER TABLE users ADD COLUMN phone TEXT').catchError((e) {
          print('  ⚠ Migration note: $e');
        });
        db
            .execute('ALTER TABLE users ADD COLUMN createdAt TEXT')
            .catchError((e) {
          print('  ⚠ Migration note: $e');
        });
        print('  ✓ Migration to version 2 completed');
      }
      return null;
    },
    // Web debug mode: automatically starts Web UI for database management
    webDebug: true,
    webDebugPort: 4800,
    // webDebugPassword: 'secret', // Optional: uncomment to enable password protection
  );

  print('✓ Database initialized (version ${db.version})\n');

  // ============================================
  // REGISTER RELATIONSHIPS (for eager loading with include)
  // ============================================
  //
  // Register relationships so we can use include() for eager loading
  // Similar to Sequelize's belongsTo, hasMany, belongsToMany
  // ============================================

  print('🔗 Registering Relationships\n');

  // Get existing model info and add relationships
  final registry = ModelRegistry();

  // Post belongsTo User (Many-to-One)
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
        'comments': RelationshipInfo(
          type: 'OneToMany',
          targetType: Comment,
          foreignKey: 'postId',
        ),
      },
      factory: postInfo.factory,
    );
    registry.register(Post, updatedPostInfo);
    print(
        '  ✓ Post relationships: author (belongsTo User), comments (hasMany Comment)');
  }

  // User hasMany Posts (One-to-Many)
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
        'comments': RelationshipInfo(
          type: 'OneToMany',
          targetType: Comment,
          foreignKey: 'userId',
        ),
      },
      factory: userInfo.factory,
    );
    registry.register(User, updatedUserInfo);
    print(
        '  ✓ User relationships: posts (hasMany Post), comments (hasMany Comment)');
  }

  // Comment belongsTo Post and User (Many-to-One)
  final commentInfo = registry.getInfo(Comment);
  if (commentInfo != null) {
    final updatedCommentInfo = ModelInfo(
      tableName: commentInfo.tableName,
      modelType: commentInfo.modelType,
      columns: commentInfo.columns,
      primaryKey: commentInfo.primaryKey,
      foreignKeys: commentInfo.foreignKeys,
      relationships: {
        'post': RelationshipInfo(
          type: 'ManyToOne',
          targetType: Post,
          foreignKey: 'postId',
        ),
        'author': RelationshipInfo(
          type: 'ManyToOne',
          targetType: User,
          foreignKey: 'userId',
        ),
      },
      factory: commentInfo.factory,
    );
    registry.register(Comment, updatedCommentInfo);
    print(
        '  ✓ Comment relationships: post (belongsTo Post), author (belongsTo User)');
  }

  print('');

  // ============================================
  // CRUD OPERATIONS - CREATE
  // ============================================

  print('📝 CREATE Operations\n');

  // Method 1: Create using map (Sequelize Model.create())
  final user1 = await db.query<User>().create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'phone': '+1234567890',
    'createdAt': DateTime.now(),
  });
  print('✓ Created user: ${user1.name} (ID: ${user1.id})');

  // Method 2: Insert using model instance
  final user2 = User()
    ..name = 'Jane Smith'
    ..email = 'jane@example.com'
    ..phone = '+0987654321'
    ..createdAt = DateTime.now();
  final userId2 = await db.query<User>().insert(user2);
  print('✓ Inserted user: ${user2.name} (ID: $userId2)');

  // Method 3: Create post
  final post1 = await db.query<Post>().create({
    'title': 'First Post',
    'content': 'This is my first post!',
    'userId': user1.id,
    'published': true,
  });
  print('✓ Created post: ${post1.title} (ID: ${post1.id})\n');

  // ============================================
  // CRUD OPERATIONS - READ
  // ============================================

  print('📖 READ Operations\n');

  // Find by primary key
  final foundUser = await db.query<User>().findByPk(user1.id!);
  print('✓ Found user by PK: ${foundUser?.name} (ID: ${foundUser?.id})');

  // Find all
  final allUsers = await db.query<User>().findAll();
  print('✓ Found ${allUsers.length} users');

  // Find first
  final firstUser = await db.query<User>().findFirst();
  print('✓ First user: ${firstUser?.name}');

  // Find with WHERE clause
  final whereClause = WhereClause().equals('email', 'jane@example.com');
  final jane = await db.query<User>().whereClause(whereClause).findFirst();
  print('✓ Found user by email: ${jane?.name}');

  // Find with multiple conditions
  final complexWhere = WhereClause()
      .equals('published', 1)
      .and(WhereClause().greaterThan('userId', 0));
  final publishedPosts =
      await db.query<Post>().whereClause(complexWhere).findAll();
  print('✓ Found ${publishedPosts.length} published posts');

  // Find with ORDER BY and LIMIT
  final recentUsers = await db
      .query<User>()
      .orderBy('createdAt', descending: true)
      .limit(5)
      .findAll();
  print('✓ Found ${recentUsers.length} recent users (ordered by createdAt)\n');

  // ============================================
  // CRUD OPERATIONS - UPDATE
  // ============================================

  print('✏️  UPDATE Operations\n');

  // Method 1: Update instance (Sequelize instance.save())
  if (foundUser != null) {
    foundUser.name = 'John Updated';
    foundUser.phone = '+1111111111';
    final updatedRows = await db.query<User>().update(foundUser);
    print('✓ Updated $updatedRows row(s) - User: ${foundUser.name}');
  }

  // Method 2: Update with WHERE clause (Sequelize Model.update())
  final updateWhere = WhereClause().equals('id', userId2);
  final updatedRows2 =
      await db.query<User>().whereClause(updateWhere).updateValues({
    'email': 'jane.updated@example.com',
    'phone': '+2222222222',
  });
  print('✓ Updated $updatedRows2 row(s) using WHERE clause');

  // Method 3: Find and update pattern
  final userToUpdate = await db.query<User>().findByPk(userId2);
  if (userToUpdate != null) {
    userToUpdate.name = 'Jane Smith Updated';
    await db.query<User>().update(userToUpdate);
    print('✓ Found and updated user: ${userToUpdate.name}\n');
  }

  // ============================================
  // CRUD OPERATIONS - DELETE
  // ============================================

  print('🗑️  DELETE Operations\n');

  // Delete with WHERE clause
  final deleteWhere = WhereClause()
      .equals('published', 0)
      .or(WhereClause().isNull('published'));
  final deletedPosts = await db.query<Post>().whereClause(deleteWhere).delete();
  print('✓ Deleted $deletedPosts unpublished post(s)');

  // Count before and after
  final totalUsers = await db.query<User>().count();
  print('✓ Total users: $totalUsers\n');

  // ============================================
  // QUERY EXAMPLES
  // ============================================

  print('🔍 Advanced Query Examples\n');

  // Select specific columns
  final usersWithNames =
      await db.query<User>().select(['id', 'name', 'email']).findAll();
  print('✓ Selected specific columns: ${usersWithNames.length} users');

  // Count with WHERE
  final activeUsersCount = await db
      .query<User>()
      .whereClause(WhereClause().isNotNull('phone'))
      .count();
  print('✓ Users with phone: $activeUsersCount');

  // Pagination
  final page1 =
      await db.query<User>().orderBy('id').limit(2).offset(0).findAll();
  print('✓ Page 1 (limit 2, offset 0): ${page1.length} users');

  final page2 =
      await db.query<User>().orderBy('id').limit(2).offset(2).findAll();
  print('✓ Page 2 (limit 2, offset 2): ${page2.length} users\n');

  // ============================================
  // TRANSACTIONS
  // ============================================

  print('💳 TRANSACTION Examples\n');

  try {
    // Transaction example - must use transaction object for all operations
    await db.transaction((Transaction txn) async {
      // Create multiple users in a transaction
      // IMPORTANT: Use queryWithTransaction() to use the transaction object
      final user3 = User()
        ..name = 'Transaction User 1'
        ..email = 'tx1@example.com';

      final user4 = User()
        ..name = 'Transaction User 2'
        ..email = 'tx2@example.com';

      // Use transaction object for all database operations
      await db.queryWithTransaction<User>(txn).insert(user3);
      await db.queryWithTransaction<User>(txn).insert(user4);

      print('✓ Transaction: Created 2 users');
      // If an error occurs, the transaction will rollback automatically
    });
    print('✓ Transaction committed successfully\n');
  } catch (e) {
    print('✗ Transaction failed: $e\n');
  }

  // Alternative: Using batch operations (sqflite best practice for bulk operations)
  try {
    print('💳 BATCH Operations Example\n');
    final batch = db.database.batch();

    // Add multiple operations to batch
    final user5 = User()
      ..name = 'Batch User 1'
      ..email = 'batch1@example.com';
    final user6 = User()
      ..name = 'Batch User 2'
      ..email = 'batch2@example.com';

    // Batch operations are more efficient for bulk inserts
    final user5Map = user5.toMap();
    user5Map.remove('id'); // Remove id for insert
    final user6Map = user6.toMap();
    user6Map.remove('id'); // Remove id for insert

    // Convert DateTime and bool for SQLite
    if (user5Map['createdAt'] is DateTime) {
      user5Map['createdAt'] =
          (user5Map['createdAt'] as DateTime).toIso8601String();
    }
    if (user6Map['createdAt'] is DateTime) {
      user6Map['createdAt'] =
          (user6Map['createdAt'] as DateTime).toIso8601String();
    }

    batch.insert('users', user5Map);
    batch.insert('users', user6Map);

    await batch.commit(noResult: true);
    print('✓ Batch: Created 2 users efficiently\n');
  } catch (e) {
    print('✗ Batch failed: $e\n');
  }

  // ============================================
  // ASSOCIATIONS / RELATIONSHIPS
  // ============================================
  //
  // This section demonstrates different types of relationships:
  // 1. Many-to-One (belongs to): Post belongs to User
  // 2. One-to-Many (has many): User has many Posts
  // 3. Many-to-Many: Posts and Tags (via join table)
  //
  // Note: The ORM uses foreign keys to establish relationships.
  // You can query related data using the QueryBuilder with WHERE clauses.
  // ============================================

  print('🔗 ASSOCIATION Examples\n');

  // Create additional data for relationship examples
  final user3 = await db.query<User>().create({
    'name': 'Alice Writer',
    'email': 'alice@example.com',
    'phone': '+3333333333',
    'createdAt': DateTime.now(),
  });

  final post2 = await db.query<Post>().create({
    'title': 'Second Post',
    'content': 'This is another post by Alice',
    'userId': user3.id,
    'published': true,
  });

  final post3 = await db.query<Post>().create({
    'title': 'Third Post',
    'content': 'Yet another post',
    'userId': user1.id,
    'published': true,
  });

  // Create comments
  final comment1 = await db.query<Comment>().create({
    'content': 'Great post!',
    'postId': post1.id,
    'userId': user2.id,
  });

  final comment2 = await db.query<Comment>().create({
    'content': 'I agree!',
    'postId': post1.id,
    'userId': user3.id,
  });

  final comment3 = await db.query<Comment>().create({
    'content': 'Nice work!',
    'postId': post2.id,
    'userId': user1.id,
  });

  print('✓ Created relationship data:\n');
  print('  - User: ${user3.name} (ID: ${user3.id})');
  print(
      '  - Posts: ${post2.title} (ID: ${post2.id}), ${post3.title} (ID: ${post3.id})');
  print(
      '  - Comments: ${comment1.content}, ${comment2.content}, ${comment3.content}\n');

  // ============================================
  // MANY-TO-ONE (Post belongs to User)
  // ============================================
  //
  // Many-to-One: Multiple posts can belong to one user
  // Foreign key: posts.userId -> users.id
  // ============================================

  print('📌 Many-to-One: Post belongs to User\n');

  // Example 1: Find posts with their authors (manual loading)
  print('  Example 1: Posts with authors (manual loading)');
  final postsWithAuthors = await db
      .query<Post>()
      .whereClause(WhereClause().equals('published', 1))
      .findAll();

  for (final post in postsWithAuthors) {
    if (post.userId != null) {
      final author = await db.query<User>().findByPk(post.userId!);
      print('    - Post: "${post.title}" by ${author?.name ?? "Unknown"}');
    }
  }

  // Example 1b: Find posts with authors using include (eager loading)
  // Note: This requires relationships to be registered in ModelInfo
  // For now, we'll show the manual approach above
  // When relationships are registered, you can use:
  // final posts = await db.query<Post>()
  //   .include(['author'])
  //   .findAll();
  // final author = posts.first.getRelation<User>('author');

  // Example 2: Find a specific post and its author
  print('\n  Example 2: Get post author by post ID');
  final firstPost = await db.query<Post>().findFirst();
  if (firstPost != null && firstPost.userId != null) {
    final postAuthor = await db.query<User>().findByPk(firstPost.userId!);
    print(
        '    - Post "${firstPost.title}" was written by: ${postAuthor?.name ?? "Unknown"}');
  }

  // Example 2b: Using findOne with include (when relationships are registered)
  // final post = await db.query<Post>()
  //   .include(['author'])
  //   .findOne();
  // final author = post?.getRelation<User>('author');

  // Example 3: Find all posts by a specific author
  print('\n  Example 3: All posts by a specific user');
  if (user1.id != null) {
    final userPosts = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user1.id!))
        .findAll();
    print('    - ${user1.name} has ${userPosts.length} post(s):');
    for (final post in userPosts) {
      print('      • ${post.title}');
    }
  }

  // Note: Using withRelations (eager loading) - when relationships are registered
  // final postsWithEager = await db.query<Post>()
  //   .withRelations(['author'])
  //   .findAll();
  // This requires relationship registration in ModelInfo

  print('');

  // ============================================
  // ONE-TO-MANY (User has many Posts)
  // ============================================
  //
  // One-to-Many: One user can have many posts
  // Foreign key: posts.userId -> users.id
  // ============================================

  print('📌 One-to-Many: User has many Posts\n');

  // Example 1: Find all users and their posts
  print('  Example 1: All users with their posts');
  final allUsersWithPosts = await db.query<User>().findAll();

  for (final user in allUsersWithPosts) {
    final userPosts = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .findAll();

    print('    - User: ${user.name} has ${userPosts.length} post(s)');
    for (final post in userPosts) {
      print('      • ${post.title}');
    }
  }

  // Example 2: Count posts per user
  print('\n  Example 2: Post count per user');
  for (final user in allUsersWithPosts) {
    final postCount = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .count();
    print('    - ${user.name}: $postCount post(s)');
  }

  // Example 3: Find users who have published posts
  print('\n  Example 3: Users with published posts');
  for (final user in allUsersWithPosts) {
    final publishedPosts = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .whereClause(WhereClause().equals('published', 1))
        .findAll();

    if (publishedPosts.isNotEmpty) {
      print(
          '    - ${user.name} has ${publishedPosts.length} published post(s)');
    }
  }

  print('');

  // ============================================
  // ONE-TO-MANY (Post has many Comments)
  // ============================================
  //
  // One-to-Many: One post can have many comments
  // Foreign key: comments.postId -> posts.id
  // Also demonstrates nested relationships: Comment -> Post -> User
  // ============================================

  print('📌 One-to-Many: Post has many Comments\n');

  // Example 1: Find all posts with their comments
  print('  Example 1: Posts with their comments');
  final allPostsWithComments = await db.query<Post>().findAll();

  for (final post in allPostsWithComments) {
    final postComments = await db
        .query<Comment>()
        .whereClause(WhereClause().equals('postId', post.id))
        .findAll();

    print('    - Post: "${post.title}" has ${postComments.length} comment(s)');
    for (final comment in postComments) {
      if (comment.userId != null) {
        final commentAuthor = await db.query<User>().findByPk(comment.userId!);
        print(
            '      • "${comment.content}" by ${commentAuthor?.name ?? "Unknown"}');
      } else {
        print('      • "${comment.content}" by Unknown');
      }
    }
  }

  // Example 2: Find most commented posts
  print('\n  Example 2: Most commented posts');
  for (final post in allPostsWithComments) {
    final commentCount = await db
        .query<Comment>()
        .whereClause(WhereClause().equals('postId', post.id))
        .count();
    if (commentCount > 0) {
      print('    - "${post.title}": $commentCount comment(s)');
    }
  }

  // Example 3: Find comments with both post and author info (nested relationship)
  print('\n  Example 3: Comments with post and author info (nested)');
  final allComments = await db.query<Comment>().findAll();
  for (final comment in allComments.take(3)) {
    // Show first 3
    if (comment.postId != null && comment.userId != null) {
      final post = await db.query<Post>().findByPk(comment.postId!);
      final author = await db.query<User>().findByPk(comment.userId!);
      print('    - "${comment.content}"');
      print('      on post: "${post?.title ?? "Unknown"}"');
      print('      by: ${author?.name ?? "Unknown"}');
    }
  }

  print('');

  // ============================================
  // MANY-TO-MANY (Posts and Tags via join table)
  // ============================================
  //
  // Many-to-Many: Many posts can have many tags, and many tags can belong to many posts
  // Requires a join table: post_tags (postId, tagId)
  // This is a common pattern for tags, categories, permissions, etc.
  // ============================================

  print('📌 Many-to-Many: Posts and Tags\n');

  // Create tags
  final tag1 = await db.query<Tag>().create({'name': 'Technology'});
  final tag2 = await db.query<Tag>().create({'name': 'Programming'});
  final tag3 = await db.query<Tag>().create({'name': 'Dart'});

  print('✓ Created tags: ${tag1.name}, ${tag2.name}, ${tag3.name}');

  // Create join table for many-to-many (post_tags)
  // In a real scenario, this would be handled by the ORM
  // For now, we'll demonstrate the concept
  try {
    await db.database.execute('''
      CREATE TABLE IF NOT EXISTS post_tags (
        postId INTEGER,
        tagId INTEGER,
        PRIMARY KEY (postId, tagId),
        FOREIGN KEY (postId) REFERENCES posts(id),
        FOREIGN KEY (tagId) REFERENCES tags(id)
      )
    ''');

    // Link posts to tags
    await db.database.execute(
      'INSERT INTO post_tags (postId, tagId) VALUES (?, ?)',
      [post1.id, tag1.id],
    );
    await db.database.execute(
      'INSERT INTO post_tags (postId, tagId) VALUES (?, ?)',
      [post1.id, tag2.id],
    );
    await db.database.execute(
      'INSERT INTO post_tags (postId, tagId) VALUES (?, ?)',
      [post2.id, tag2.id],
    );
    await db.database.execute(
      'INSERT INTO post_tags (postId, tagId) VALUES (?, ?)',
      [post2.id, tag3.id],
    );

    print('✓ Linked posts to tags via join table\n');

    // Query posts with their tags (manual join)
    final postsWithTags = await db.query<Post>().findAll();
    for (final post in postsWithTags) {
      final tagRows = await db.database.rawQuery(
        '''
        SELECT t.* FROM tags t
        INNER JOIN post_tags pt ON t.id = pt.tagId
        WHERE pt.postId = ?
        ''',
        [post.id],
      );

      final tagNames = tagRows.map((row) => row['name'] as String).join(', ');
      print(
          '  - Post: "${post.title}" tagged with: ${tagNames.isEmpty ? "None" : tagNames}');
    }
  } catch (e) {
    print('  ⚠ Many-to-many example: $e');
  }

  print('');

  // ============================================
  // COMPLEX RELATIONSHIP QUERIES
  // ============================================
  //
  // These examples show how to combine multiple relationships
  // and use raw SQL for complex queries when needed.
  // ============================================

  print('📌 Complex Relationship Queries\n');

  // Example 1: Find all posts by a specific user with comment counts
  print('  Example 1: User posts with comment counts');
  if (user1.id != null) {
    final userPosts = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user1.id!))
        .findAll();

    print('    Posts by ${user1.name}:');
    for (final post in userPosts) {
      final comments = await db
          .query<Comment>()
          .whereClause(WhereClause().equals('postId', post.id))
          .count();
      print('      - "${post.title}" (${comments} comments)');
    }
  }

  // Example 2: Find users who have commented (using raw SQL for DISTINCT)
  print('\n  Example 2: Users who have commented (using raw SQL)');
  final commenters = await db.database.rawQuery('''
    SELECT DISTINCT u.* FROM users u
    INNER JOIN comments c ON u.id = c.userId
  ''');

  print('    Found ${commenters.length} user(s) who have commented:');
  for (final row in commenters) {
    print('      - ${row['name']} (${row['email']})');
  }

  // Example 3: Find posts with comment count (using raw SQL for aggregation)
  print('\n  Example 3: Posts with comment counts (aggregation)');
  final postsWithCounts = await db.database.rawQuery('''
    SELECT p.*, COUNT(c.id) as commentCount
    FROM posts p
    LEFT JOIN comments c ON p.id = c.postId
    GROUP BY p.id
    ORDER BY commentCount DESC
  ''');

  print('    Posts sorted by comment count:');
  for (final row in postsWithCounts) {
    print('      - "${row['title']}": ${row['commentCount']} comment(s)');
  }

  // Example 4: Find posts by users who have more than 1 post
  print('\n  Example 4: Users with multiple posts');
  final usersForMultiPost = await db.query<User>().findAll();
  for (final user in usersForMultiPost) {
    final postCount = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .count();
    if (postCount > 1) {
      print('      - ${user.name} has $postCount posts');
    }
  }

  // Example 5: Find posts with their author and comment count (nested relationships)
  print('\n  Example 5: Posts with author info and comment count');
  final publishedPostsForComplex = await db
      .query<Post>()
      .whereClause(WhereClause().equals('published', 1))
      .findAll();

  for (final post in publishedPostsForComplex.take(3)) {
    // Show first 3
    if (post.userId != null) {
      final author = await db.query<User>().findByPk(post.userId!);
      final commentCount = await db
          .query<Comment>()
          .whereClause(WhereClause().equals('postId', post.id))
          .count();
      print('      - "${post.title}"');
      print('        Author: ${author?.name ?? "Unknown"}');
      print('        Comments: $commentCount');
    }
  }

  print('');

  // ============================================
  // FINAL STATE
  // ============================================

  print('📊 Final Database State\n');
  final finalUsers = await db.query<User>().findAll();
  final finalPosts = await db.query<Post>().findAll();
  final finalComments = await db.query<Comment>().findAll();
  final finalTags = await db.query<Tag>().findAll();

  print('✓ Total users: ${finalUsers.length}');
  for (final user in finalUsers) {
    print('  - ${user.name} (${user.email}) - Phone: ${user.phone ?? "N/A"}');
  }

  print('✓ Total posts: ${finalPosts.length}');
  for (final post in finalPosts) {
    print(
        '  - ${post.title} (Published: ${post.published}, User: ${post.userId})');
  }

  print('✓ Total comments: ${finalComments.length}');
  for (final comment in finalComments) {
    print(
        '  - "${comment.content}" (Post: ${comment.postId}, User: ${comment.userId})');
  }

  print('✓ Total tags: ${finalTags.length}');
  for (final tag in finalTags) {
    print('  - ${tag.name}');
  }

  // ============================================
  // EAGER LOADING WITH INCLUDE (Sequelize-style)
  // ============================================
  //
  // Demonstrates using include() for eager loading associations
  // Similar to Sequelize's include option
  // ============================================

  print('📦 Eager Loading with include() (Sequelize-style)\n');

  // Example 1: findAll() with include - Posts with authors
  print('  Example 1: findAll() with include - Posts with authors');
  print(
      '    Similar to: Post.findAll({ include: [{ model: User, as: \'author\' }] })');

  final postsWithAuthorsEager = await db
      .query<Post>()
      .include(['author'])
      .whereClause(WhereClause().equals('published', 1))
      .findAll();

  for (final post in postsWithAuthorsEager.take(3)) {
    final author = post.getRelation<User>('author');
    print('    - Post: "${post.title}" by ${author?.name ?? "Unknown"}');
  }

  // Example 2: findOne() with include - User with posts
  print('\n  Example 2: findOne() with include - User with posts');
  print(
      '    Similar to: User.findOne({ include: [{ model: Post, as: \'posts\' }] })');

  if (user1.id != null) {
    final userWithPosts =
        await db.query<User>().include(['posts']).findByPk(user1.id!);

    if (userWithPosts != null) {
      final posts = userWithPosts.getRelationList<Post>('posts');
      print('    - User: ${userWithPosts.name} has ${posts.length} post(s)');
      for (final post in posts.take(3)) {
        print('      • ${post.title}');
      }
    }
  }

  // Example 3: findByPk() with multiple includes - Post with author and comments
  print('\n  Example 3: findByPk() with multiple includes');
  print('    Similar to: Post.findByPk(1, { include: [');
  print('      { model: User, as: \'author\' },');
  print('      { model: Comment, as: \'comments\' }');
  print('    ]})');

  final firstPostId = await db.query<Post>().findFirst();
  if (firstPostId?.id != null) {
    final postWithRelations = await db
        .query<Post>()
        .include(['author', 'comments']).findByPk(firstPostId!.id!);

    if (postWithRelations != null) {
      final author = postWithRelations.getRelation<User>('author');
      final comments = postWithRelations.getRelationList<Comment>('comments');
      print('    - Post: "${postWithRelations.title}"');
      print('      Author: ${author?.name ?? "Unknown"}');
      print('      Comments: ${comments.length}');
      for (final comment in comments.take(2)) {
        print('        • "${comment.content}"');
      }
    }
  }

  // Example 4: Nested includes - Comment with post and author
  print('\n  Example 4: Nested includes - Comment with post and author');
  print('    Similar to: Comment.findOne({ include: [');
  print('      { model: Post, as: \'post\' },');
  print('      { model: User, as: \'author\' }');
  print('    ]})');

  final firstComment = await db.query<Comment>().findFirst();
  if (firstComment?.id != null) {
    final commentWithRelations = await db
        .query<Comment>()
        .include(['post', 'author']).findByPk(firstComment!.id!);

    if (commentWithRelations != null) {
      final post = commentWithRelations.getRelation<Post>('post');
      final author = commentWithRelations.getRelation<User>('author');
      print('    - Comment: "${commentWithRelations.content}"');
      print('      On post: "${post?.title ?? "Unknown"}"');
      print('      By: ${author?.name ?? "Unknown"}');
    }
  }

  // Example 5: User with posts and comments count
  print('\n  Example 5: findAll() with include - Users with their posts');
  print(
      '    Similar to: User.findAll({ include: [{ model: Post, as: \'posts\' }] })');

  final usersWithPosts =
      await db.query<User>().include(['posts']).limit(3).findAll();

  for (final user in usersWithPosts) {
    final posts = user.getRelationList<Post>('posts');
    print('    - ${user.name}: ${posts.length} post(s)');
  }

  print('');

  // ============================================
  // WEB UI (automatically started when debug: true)
  // ============================================

  print('\n🌐 Web UI is running (started automatically with debug mode)');
  print('✓ Access at: http://localhost:4800');
  print('\nPress Ctrl+C to stop the server\n');

  // Keep the process alive
  try {
    await Future.delayed(Duration(days: 1));
  } catch (e) {
    // Handle interruption
    print('\n🛑 Shutting down...');
    await db.close();
    print('✓ Cleanup completed');
  }
}
