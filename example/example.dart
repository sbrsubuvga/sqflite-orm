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
      // Additional setup can be done here
      // Note: For async operations, use .then() or handle them synchronously
      return null;
    },
    // Custom onUpgrade callback (called when version changes)
    onUpgrade: (Database db, int oldVersion, int newVersion) {
      // Manual migration example
      if (oldVersion < 2) {
        // These will be added automatically by MigrationManager,
        // but you can add custom migration logic here
        db.execute('ALTER TABLE users ADD COLUMN phone TEXT').catchError((e) {
          // Migration error handling
        });
        db
            .execute('ALTER TABLE users ADD COLUMN createdAt TEXT')
            .catchError((e) {
          // Migration error handling
        });
      }
      return null;
    },
    // Web debug mode: automatically starts Web UI for database management
    webDebug: true,
    webDebugPort: 4800,
    // webDebugPassword: 'secret', // Optional: uncomment to enable password protection
  );

  // ============================================
  // REGISTER RELATIONSHIPS (for eager loading with include)
  // ============================================
  //
  // Register relationships so we can use include() for eager loading
  // Similar to Sequelize's belongsTo, hasMany, belongsToMany
  // ============================================

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
  }

  // ============================================
  // CRUD OPERATIONS - CREATE
  // ============================================

  // Method 1: Create using map (Sequelize Model.create())
  final user1 = await db.query<User>().create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'phone': '+1234567890',
    'createdAt': DateTime.now(),
  });

  // Method 2: Insert using model instance
  final user2 = User()
    ..name = 'Jane Smith'
    ..email = 'jane@example.com'
    ..phone = '+0987654321'
    ..createdAt = DateTime.now();
  final userId2 = await db.query<User>().insert(user2);

  // Method 3: Create post
  final post1 = await db.query<Post>().create({
    'title': 'First Post',
    'content': 'This is my first post!',
    'userId': user1.id,
    'published': true,
  });

  // ============================================
  // CRUD OPERATIONS - READ
  // ============================================

  // Find by primary key
  final foundUser = await db.query<User>().findByPk(user1.id!);

  // Find all
  await db.query<User>().findAll();

  // Find first
  await db.query<User>().findFirst();

  // Find with WHERE clause
  final whereClause = WhereClause().equals('email', 'jane@example.com');
  await db.query<User>().whereClause(whereClause).findFirst();

  // Find with multiple conditions
  final complexWhere = WhereClause()
      .equals('published', 1)
      .and(WhereClause().greaterThan('userId', 0));
  await db.query<Post>().whereClause(complexWhere).findAll();

  // Find with ORDER BY and LIMIT
  await db
      .query<User>()
      .orderBy('createdAt', descending: true)
      .limit(5)
      .findAll();

  // ============================================
  // CRUD OPERATIONS - UPDATE
  // ============================================

  // Method 1: Update instance (Sequelize instance.save())
  if (foundUser != null) {
    foundUser.name = 'John Updated';
    foundUser.phone = '+1111111111';
    await db.query<User>().update(foundUser);
  }

  // Method 2: Update with WHERE clause (Sequelize Model.update())
  final updateWhere = WhereClause().equals('id', userId2);
  await db.query<User>().whereClause(updateWhere).updateValues({
    'email': 'jane.updated@example.com',
    'phone': '+2222222222',
  });

  // Method 3: Find and update pattern
  final userToUpdate = await db.query<User>().findByPk(userId2);
  if (userToUpdate != null) {
    userToUpdate.name = 'Jane Smith Updated';
    await db.query<User>().update(userToUpdate);
  }

  // ============================================
  // CRUD OPERATIONS - DELETE
  // ============================================

  // Delete with WHERE clause
  final deleteWhere = WhereClause()
      .equals('published', 0)
      .or(WhereClause().isNull('published'));
  await db.query<Post>().whereClause(deleteWhere).delete();

  // Count before and after
  await db.query<User>().count();

  // ============================================
  // QUERY EXAMPLES
  // ============================================

  // Select specific columns
  await db.query<User>().select(['id', 'name', 'email']).findAll();

  // Count with WHERE
  await db.query<User>().whereClause(WhereClause().isNotNull('phone')).count();

  // Pagination
  await db.query<User>().orderBy('id').limit(2).offset(0).findAll();

  await db.query<User>().orderBy('id').limit(2).offset(2).findAll();

  // ============================================
  // TRANSACTIONS
  // ============================================

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

      // If an error occurs, the transaction will rollback automatically
    });
  } catch (e) {
    // Transaction failed
  }

  // Alternative: Using batch operations (sqflite best practice for bulk operations)
  try {
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
  } catch (e) {
    // Batch failed
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

  await db.query<Post>().create({
    'title': 'Third Post',
    'content': 'Yet another post',
    'userId': user1.id,
    'published': true,
  });

  // Create comments
  await db.query<Comment>().create({
    'content': 'Great post!',
    'postId': post1.id,
    'userId': user2.id,
  });

  await db.query<Comment>().create({
    'content': 'I agree!',
    'postId': post1.id,
    'userId': user3.id,
  });

  await db.query<Comment>().create({
    'content': 'Nice work!',
    'postId': post2.id,
    'userId': user1.id,
  });

  // ============================================
  // MANY-TO-ONE (Post belongs to User)
  // ============================================
  //
  // Many-to-One: Multiple posts can belong to one user
  // Foreign key: posts.userId -> users.id
  // ============================================

  // Example 1: Find posts with their authors (manual loading)
  final postsWithAuthors = await db
      .query<Post>()
      .whereClause(WhereClause().equals('published', 1))
      .findAll();

  for (final post in postsWithAuthors) {
    if (post.userId != null) {
      await db.query<User>().findByPk(post.userId!);
    }
  }

  // Example 2: Find a specific post and its author
  final firstPost = await db.query<Post>().findFirst();
  if (firstPost != null && firstPost.userId != null) {
    await db.query<User>().findByPk(firstPost.userId!);
  }

  // Example 3: Find all posts by a specific author
  if (user1.id != null) {
    await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user1.id!))
        .findAll();
  }

  // ============================================
  // ONE-TO-MANY (User has many Posts)
  // ============================================
  //
  // One-to-Many: One user can have many posts
  // Foreign key: posts.userId -> users.id
  // ============================================

  // Example 1: Find all users and their posts
  final allUsersWithPosts = await db.query<User>().findAll();

  for (final user in allUsersWithPosts) {
    await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .findAll();
  }

  // Example 2: Count posts per user
  for (final user in allUsersWithPosts) {
    await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .count();
  }

  // Example 3: Find users who have published posts
  for (final user in allUsersWithPosts) {
    await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .whereClause(WhereClause().equals('published', 1))
        .findAll();
  }

  // ============================================
  // ONE-TO-MANY (Post has many Comments)
  // ============================================
  //
  // One-to-Many: One post can have many comments
  // Foreign key: comments.postId -> posts.id
  // Also demonstrates nested relationships: Comment -> Post -> User
  // ============================================

  // Example 1: Find all posts with their comments
  final allPostsWithComments = await db.query<Post>().findAll();

  for (final post in allPostsWithComments) {
    await db
        .query<Comment>()
        .whereClause(WhereClause().equals('postId', post.id))
        .findAll();
  }

  // Example 2: Find most commented posts
  for (final post in allPostsWithComments) {
    await db
        .query<Comment>()
        .whereClause(WhereClause().equals('postId', post.id))
        .count();
  }

  // Example 3: Find comments with both post and author info (nested relationship)
  final allComments = await db.query<Comment>().findAll();
  for (final comment in allComments.take(3)) {
    if (comment.postId != null && comment.userId != null) {
      await db.query<Post>().findByPk(comment.postId!);
      await db.query<User>().findByPk(comment.userId!);
    }
  }

  // ============================================
  // MANY-TO-MANY (Posts and Tags via join table)
  // ============================================
  //
  // Many-to-Many: Many posts can have many tags, and many tags can belong to many posts
  // Requires a join table: post_tags (postId, tagId)
  // This is a common pattern for tags, categories, permissions, etc.
  // ============================================

  // Create tags
  final tag1 = await db.query<Tag>().create({'name': 'Technology'});
  final tag2 = await db.query<Tag>().create({'name': 'Programming'});
  final tag3 = await db.query<Tag>().create({'name': 'Dart'});

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

    // Query posts with their tags (manual join)
    final postsWithTags = await db.query<Post>().findAll();
    for (final post in postsWithTags) {
      await db.database.rawQuery(
        '''
        SELECT t.* FROM tags t
        INNER JOIN post_tags pt ON t.id = pt.tagId
        WHERE pt.postId = ?
        ''',
        [post.id],
      );
    }
  } catch (e) {
    // Many-to-many example error
  }

  // ============================================
  // COMPLEX RELATIONSHIP QUERIES
  // ============================================
  //
  // These examples show how to combine multiple relationships
  // and use raw SQL for complex queries when needed.
  // ============================================

  // Example 1: Find all posts by a specific user with comment counts
  if (user1.id != null) {
    final userPosts = await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user1.id!))
        .findAll();

    for (final post in userPosts) {
      await db
          .query<Comment>()
          .whereClause(WhereClause().equals('postId', post.id))
          .count();
    }
  }

  // Example 2: Find users who have commented (using raw SQL for DISTINCT)
  await db.database.rawQuery('''
    SELECT DISTINCT u.* FROM users u
    INNER JOIN comments c ON u.id = c.userId
  ''');

  // Example 3: Find posts with comment count (using raw SQL for aggregation)
  await db.database.rawQuery('''
    SELECT p.*, COUNT(c.id) as commentCount
    FROM posts p
    LEFT JOIN comments c ON p.id = c.postId
    GROUP BY p.id
    ORDER BY commentCount DESC
  ''');

  // Example 4: Find posts by users who have more than 1 post
  final usersForMultiPost = await db.query<User>().findAll();
  for (final user in usersForMultiPost) {
    await db
        .query<Post>()
        .whereClause(WhereClause().equals('userId', user.id))
        .count();
  }

  // Example 5: Find posts with their author and comment count (nested relationships)
  final publishedPostsForComplex = await db
      .query<Post>()
      .whereClause(WhereClause().equals('published', 1))
      .findAll();

  for (final post in publishedPostsForComplex.take(3)) {
    if (post.userId != null) {
      await db.query<User>().findByPk(post.userId!);
      await db
          .query<Comment>()
          .whereClause(WhereClause().equals('postId', post.id))
          .count();
    }
  }

  // ============================================
  // FINAL STATE
  // ============================================

  await db.query<User>().findAll();
  await db.query<Post>().findAll();
  await db.query<Comment>().findAll();
  await db.query<Tag>().findAll();

  // ============================================
  // EAGER LOADING WITH INCLUDE (Sequelize-style)
  // ============================================
  //
  // Demonstrates using include() for eager loading associations
  // Similar to Sequelize's include option
  // ============================================

  // Example 1: findAll() with include - Posts with authors
  final postsWithAuthorsEager = await db
      .query<Post>()
      .include(['author'])
      .whereClause(WhereClause().equals('published', 1))
      .findAll();

  for (final post in postsWithAuthorsEager.take(3)) {
    post.getRelation<User>('author');
  }

  // Example 2: findOne() with include - User with posts
  if (user1.id != null) {
    final userWithPosts =
        await db.query<User>().include(['posts']).findByPk(user1.id!);

    if (userWithPosts != null) {
      userWithPosts.getRelationList<Post>('posts');
    }
  }

  // Example 3: findByPk() with multiple includes - Post with author and comments
  final firstPostId = await db.query<Post>().findFirst();
  if (firstPostId?.id != null) {
    final postWithRelations = await db
        .query<Post>()
        .include(['author', 'comments']).findByPk(firstPostId!.id!);

    if (postWithRelations != null) {
      postWithRelations.getRelation<User>('author');
      postWithRelations.getRelationList<Comment>('comments');
    }
  }

  // Example 4: Nested includes - Comment with post and author
  final firstComment = await db.query<Comment>().findFirst();
  if (firstComment?.id != null) {
    final commentWithRelations = await db
        .query<Comment>()
        .include(['post', 'author']).findByPk(firstComment!.id!);

    if (commentWithRelations != null) {
      commentWithRelations.getRelation<Post>('post');
      commentWithRelations.getRelation<User>('author');
    }
  }

  // Example 5: User with posts and comments count
  final usersWithPosts =
      await db.query<User>().include(['posts']).limit(3).findAll();

  for (final user in usersWithPosts) {
    user.getRelationList<Post>('posts');
  }

  // ============================================
  // WEB UI (automatically started when debug: true)
  // ============================================

  // Keep the process alive
  try {
    await Future.delayed(Duration(days: 1));
  } catch (e) {
    // Handle interruption
    await db.close();
  }
}
