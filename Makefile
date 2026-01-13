.PHONY: publish-dry-run publish clean-publish prepare-publish restore-publish

# Publish with temporary sqflite dependency
# This approach maintains optimal pub.dev scoring by not permanently including sqflite
# sqflite is only added temporarily for pub publish validation, then removed

# Prepare pubspec.yaml for publishing (adds sqflite temporarily)
prepare-publish:
	@echo "🔧 Preparing pubspec.yaml for publishing..."
	@dart run tool/publish_helper.dart
	@dart pub get

# Restore pubspec.yaml after publishing
restore-publish:
	@echo "🔄 Restoring pubspec.yaml..."
	@dart run tool/publish_helper.dart --restore
	@dart pub get

# Dry-run publish (validates without actually publishing)
publish-dry-run: prepare-publish
	@echo "🔍 Running pub publish --dry-run..."
	@dart pub publish --dry-run || (make restore-publish && exit 1)
	@make restore-publish
	@echo "✅ Dry-run completed successfully!"

# Actual publish to pub.dev
publish: prepare-publish
	@echo "🚀 Publishing to pub.dev..."
	@dart pub publish || (make restore-publish && exit 1)
	@make restore-publish
	@echo "✅ Published successfully!"

# Clean up any leftover backup files
clean-publish:
	@echo "🧹 Cleaning up..."
	@dart run tool/publish_helper.dart --restore

