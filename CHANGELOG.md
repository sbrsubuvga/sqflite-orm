## 0.1.8

* Added comprehensive dartdoc documentation for all public APIs
* Documented QueryResult, RelationshipManager, AssociationLoader, MigrationManager, SchemaValidator, ConnectionPool
* Enhanced documentation for ModelInfo, ColumnInfo, ForeignKeyInfo, RelationshipInfo classes
* Added detailed documentation for relationship annotations (OneToMany, ManyToOne, ManyToMany)
* Increased documentation coverage from 673 to 984 comments (46% increase)
* All code passes Flutter analysis with no errors, warnings, or lint issues

## 0.1.7

* Updated sqflite_dev to ^1.0.5 (latest version)
* Updated Web UI screenshot in README
* Enhanced documentation for DatabaseManager constructor and registerInstanceCreator method
* All code passes Flutter analysis with no issues

## 0.1.6

* Added sqflite back to package dependencies - package now manages it automatically
* Users no longer need to manually add sqflite to their pubspec.yaml
* Fixed pub.dev validation issues (shortened description to meet 60-180 character requirement)
* Improved installation experience - single dependency required

## 0.1.5

* Simplified sqflite_dev integration - removed unnecessary conditional imports
* sqflite_dev now directly imported since it supports both Flutter and pure Dart
* Improved code simplicity and maintainability

## 0.1.4

* Added comprehensive dartdoc documentation for public API (20%+ coverage)
* Added `analysis_options.yaml` with Flutter linting configuration
* Fixed all linting and formatting issues
* Tightened dependency constraints for better compatibility
* Added platform support declarations (Android, iOS, Windows, macOS, Linux)
* Added `sqflite_common` to dependencies for proper pub.dev validation

## 0.1.3

* Fixed conditional imports for mobile factory to prevent Flutter dependency errors in pure Dart scripts
* Improved platform detection logic to prioritize desktop platforms
* Example now works correctly in both Flutter apps and pure Dart scripts

## 0.1.2

* Added Finzo example app reference in README

## 0.1.1

* Network access support for Web UI when debugging on Android devices
* Improved Web UI with better pagination and styling


## 0.1.0

* Initial release
* Cross-platform SQLite database support (desktop, Android, iOS)
* ORM with annotations (@Table, @Column, @PrimaryKey, @ForeignKey)
* Relationship support (OneToMany, ManyToOne, ManyToMany)
* Query builder with fluent API
* Automatic migrations
* Schema validation at runtime
* Web UI for database management (localhost:4800)
* Transaction support

