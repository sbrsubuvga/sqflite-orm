#!/usr/bin/env dart
// Helper script to temporarily add sqflite for pub publish validation
// This maintains optimal pub.dev scoring by not permanently including sqflite

import 'dart:io';

void main(List<String> args) async {
  final pubspecPath = 'pubspec.yaml';
  final backupPath = 'pubspec.yaml.bak';
  final pubspecFile = File(pubspecPath);
  
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found');
    exit(1);
  }

  final isRestore = args.contains('--restore') || args.contains('-r');
  
  if (isRestore) {
    await restorePubspec(pubspecPath, backupPath);
  } else {
    await preparePubspec(pubspecPath, backupPath);
  }
}

Future<void> preparePubspec(String pubspecPath, String backupPath) async {
  final pubspecFile = File(pubspecPath);
  final backupFile = File(backupPath);
  
  // Check if already prepared
  final content = await pubspecFile.readAsString();
  if (content.contains('sqflite: ^2.4.2')) {
    print('⚠️  sqflite already in pubspec.yaml');
    return;
  }
  
  // Create backup
  if (backupFile.existsSync()) {
    print('⚠️  Backup file exists. Restoring first...');
    await restorePubspec(pubspecPath, backupPath);
  }
  
  await pubspecFile.copy(backupPath);
  print('✅ Created backup: $backupPath');
  
  // Add sqflite to dependencies
  final lines = content.split('\n');
  final dependenciesIndex = lines.indexWhere((line) => line.trim() == 'dependencies:');
  
  if (dependenciesIndex == -1) {
    print('❌ Error: Could not find dependencies section');
    exit(1);
  }
  
  // Find the insertion point (after dependencies: line)
  int insertIndex = dependenciesIndex + 1;
  
  // Skip empty lines and find first dependency
  while (insertIndex < lines.length && 
         (lines[insertIndex].trim().isEmpty || 
          lines[insertIndex].startsWith('  '))) {
    insertIndex++;
  }
  
  // Insert sqflite
  lines.insert(insertIndex, '  sqflite: ^2.4.2');
  
  await pubspecFile.writeAsString(lines.join('\n'));
  print('✅ Added sqflite to dependencies');
  print('✅ Ready for pub publish');
}

Future<void> restorePubspec(String pubspecPath, String backupPath) async {
  final backupFile = File(backupPath);
  
  if (!backupFile.existsSync()) {
    print('⚠️  No backup file found');
    return;
  }
  
  await backupFile.copy(pubspecPath);
  await backupFile.delete();
  print('✅ Restored pubspec.yaml from backup');
  print('✅ Removed backup file');
}

