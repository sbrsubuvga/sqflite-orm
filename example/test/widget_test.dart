// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_orm/sqflite_orm.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App loads and displays correctly', (WidgetTester tester) async {
    // Create a mock database manager for testing
    // In a real scenario, you might want to use a test database
    final db = await DatabaseManager.initialize(
      path: 'test.db',
      version: 1,
      models: [User, Post],
      instanceCreators: {
        User: () => User(),
        Post: () => Post(),
      },
      webDebug: false,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(db: db));

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('SQLite ORM Example'), findsOneWidget);

    // Verify that tabs are present
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);

    // Clean up
    await db.close();
  });
}
