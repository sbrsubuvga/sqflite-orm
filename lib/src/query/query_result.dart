/// Wrapper for query results
class QueryResult<T> {
  final List<T> data;
  final int? totalCount;
  final int page;
  final int pageSize;

  QueryResult({
    required this.data,
    this.totalCount,
    this.page = 1,
    this.pageSize = 0,
  });

  /// Check if there are more pages
  bool get hasMore {
    if (totalCount == null) return false;
    return (page * pageSize) < totalCount!;
  }

  /// Get the total number of pages
  int? get totalPages {
    if (totalCount == null || pageSize == 0) return null;
    return (totalCount! / pageSize).ceil();
  }
}

