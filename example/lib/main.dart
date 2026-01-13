import 'package:flutter/material.dart';
import 'package:sqflite_orm/sqflite_orm.dart' hide Table, Column;
import 'package:sqflite_orm/sqflite_orm.dart'
    as orm
    show Table, Column, PrimaryKey;

// ============================================
// MODEL DEFINITIONS
// ============================================

/// User model
@orm.Table(name: 'users')
class User extends BaseModel {
  @orm.PrimaryKey()
  @orm.Column(name: 'id')
  int? id;

  @orm.Column(name: 'name')
  String? name;

  @orm.Column(name: 'email')
  String? email;

  @orm.Column(name: 'phone')
  String? phone;

  @orm.Column(name: 'createdAt')
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
@orm.Table(name: 'posts')
class Post extends BaseModel {
  @orm.PrimaryKey()
  @orm.Column(name: 'id')
  int? id;

  @orm.Column(name: 'title')
  String? title;

  @orm.Column(name: 'content')
  String? content;

  @orm.Column(name: 'userId')
  int? userId;

  @orm.Column(name: 'published')
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
// FLUTTER APP
// ============================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final db = await DatabaseManager.initialize(
    path: 'example.db',
    version: 1,
    models: [User, Post],
    instanceCreators: {User: () => User(), Post: () => Post()},
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

  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final DatabaseManager db;

  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite ORM Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(db: db),
    );
  }
}

class HomePage extends StatefulWidget {
  final DatabaseManager db;

  const HomePage({super.key, required this.db});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<User> _users = [];
  List<Post> _posts = [];
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final users = await widget.db.query<User>().findAll();
      final posts = await widget.db.query<Post>().findAll();

      setState(() {
        _users = users;
        _posts = posts;
        _loading = false;
        _message = 'Loaded ${users.length} users and ${posts.length} posts';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _message = 'Error: $e';
      });
    }
  }

  Future<void> _createUser() async {
    try {
      final user = await widget.db.query<User>().create({
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'createdAt': DateTime.now(),
      });

      setState(() {
        _message = 'Created user: ${user.name} (ID: ${user.id})';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _message = 'Error creating user: $e';
      });
    }
  }

  Future<void> _createPost() async {
    if (_users.isEmpty) {
      setState(() {
        _message = 'Please create a user first';
      });
      return;
    }

    try {
      final post = await widget.db.query<Post>().create({
        'title': 'My First Post',
        'content': 'This is a sample post created from the Flutter app!',
        'userId': _users.first.id,
        'published': true,
      });

      setState(() {
        _message = 'Created post: ${post.title} (ID: ${post.id})';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _message = 'Error creating post: $e';
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      await widget.db
          .query<User>()
          .whereClause(WhereClause().equals('id', userId))
          .delete();

      setState(() {
        _message = 'Deleted user ID: $userId';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _message = 'Error deleting user: $e';
      });
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      await widget.db
          .query<Post>()
          .whereClause(WhereClause().equals('id', postId))
          .delete();

      setState(() {
        _message = 'Deleted post ID: $postId';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _message = 'Error deleting post: $e';
      });
    }
  }

  Future<void> _queryWithInclude() async {
    try {
      final posts = await widget.db.query<Post>().include(['author']).findAll();

      setState(() {
        _message = 'Loaded ${posts.length} posts with authors (eager loading)';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('SQLite ORM Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Message bar
          if (_message.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(_message, style: const TextStyle(fontSize: 14)),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _createUser,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create User'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _createPost,
                  icon: const Icon(Icons.post_add),
                  label: const Text('Create Post'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _queryWithInclude,
                  icon: const Icon(Icons.search),
                  label: const Text('Query with Include'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Users', icon: Icon(Icons.people)),
                            Tab(text: 'Posts', icon: Icon(Icons.article)),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Users tab
                              _users.isEmpty
                                  ? const Center(
                                      child: Text('No users yet. Create one!'),
                                    )
                                  : ListView.builder(
                                      itemCount: _users.length,
                                      itemBuilder: (context, index) {
                                        final user = _users[index];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            child: Text(user.name?[0] ?? '?'),
                                          ),
                                          title: Text(user.name ?? 'Unknown'),
                                          subtitle: Text(user.email ?? ''),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                _deleteUser(user.id!),
                                          ),
                                        );
                                      },
                                    ),

                              // Posts tab
                              _posts.isEmpty
                                  ? const Center(
                                      child: Text('No posts yet. Create one!'),
                                    )
                                  : ListView.builder(
                                      itemCount: _posts.length,
                                      itemBuilder: (context, index) {
                                        final post = _posts[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: ListTile(
                                            title: Text(post.title ?? ''),
                                            subtitle: Text(post.content ?? ''),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  _deletePost(post.id!),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
