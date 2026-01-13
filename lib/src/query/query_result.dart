/// Wrapper for paginated query results.
///
/// Provides metadata about paginated query results including
/// the data, total count, current page, and pagination information.
///
/// Example:
/// ```dart
/// final result = QueryResult<User>(
///   data: users,
///   totalCount: 100,
///   page: 1,
///   pageSize: 10,
/// );
///
/// if (result.hasMore) {
///   // Load next page
/// }
/// ```
class QueryResult<T> {
  /// The list of results for the current page.
  final List<T> data;

  /// Total number of records matching the query (across all pages).
  ///
  /// If `null`, the total count is unknown.
  final int? totalCount;

  /// Current page number (1-indexed).
  final int page;

  /// Number of items per page.
  final int pageSize;

  /// Create a query result.
  ///
  /// [data] is the list of results for the current page.
  /// [totalCount] is the total number of records (optional).
  /// [page] is the current page number (defaults to 1).
  /// [pageSize] is the number of items per page (defaults to 0).
  QueryResult({
    required this.data,
    this.totalCount,
    this.page = 1,
    this.pageSize = 0,
  });

  /// Check if there are more pages available.
  ///
  /// Returns `true` if there are more records beyond the current page.
  /// Returns `false` if this is the last page or if total count is unknown.
  bool get hasMore {
    if (totalCount == null) return false;
    return (page * pageSize) < totalCount!;
  }

  /// Get the total number of pages.
  ///
  /// Returns `null` if total count or page size is not available.
  /// Otherwise returns the calculated number of pages.
  int? get totalPages {
    if (totalCount == null || pageSize == 0) return null;
    return (totalCount! / pageSize).ceil();
  }
}
