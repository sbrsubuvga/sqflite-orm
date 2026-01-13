## 0.1.15

* Dependency updates
  - Updated `sqflite_dev` to ^1.0.6 (latest available version)
  - Added `dependency_validator` for dependency validation

* Documentation
  - Updated README to clarify `sqflite` dependency status
  - Updated CHANGELOG with accurate dependency information

## 0.1.14

* Improved conditional import architecture for cross-platform support
  - Added `sqflite` to dependencies (required for pub publish validation)
  - Package still works without requiring users to add `sqflite` - uses conditional imports
  - Pure Dart packages can use the ORM without Flutter SDK (automatically uses `sqflite_common_ffi`)
  - `sqflite_common_ffi` now works on all platforms including Android/iOS (via FFI)
  - Better fallback mechanism: Flutter apps without `sqflite` automatically use `sqflite_common_ffi`
  - Updated documentation to clarify platform support and architecture
  - Added architecture section in README explaining conditional import pattern
  - Fixed pub publish validation errors

* Documentation improvements
  - Clarified that `sqflite` is included in package dependencies but optional for users
  - Documented that `sqflite_common_ffi` works on all platforms (not just desktop)
  - Added platform selection logic diagram
  - Updated installation instructions with platform-specific setup guides
  - Updated README to reflect current dependency structure

## 0.1.13

* Achieved perfect pub points score 
  - Package now scores maximum points on pub.dev
  - All validation checks pass: platform support , static analysis , up-to-date dependencies
  - Package verified with `pana` analysis tool locally


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

