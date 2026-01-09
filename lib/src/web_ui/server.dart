import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;
import 'package:sqflite_orm/src/web_ui/handlers/auth_handler.dart';
import 'package:sqflite_orm/src/web_ui/handlers/cors_handler.dart';
import 'package:sqflite_orm/src/web_ui/routes/tables_route.dart';
import 'package:sqflite_orm/src/web_ui/routes/data_route.dart';
import 'package:sqflite_orm/src/web_ui/routes/query_route.dart';
import 'package:sqflite_orm/src/web_ui/routes/schema_route.dart';
import 'dart:convert';

/// Web UI server for database management
class WebUI {
  static HttpServer? _server;
  // Database reference is passed to routes, not stored here

  /// Start the web UI server
  static Future<void> start(
    Database database, {
    int port = 4800,
    String? password,
    bool tryNextPort = true,
  }) async {

    final authHandler = AuthHandler(password: password);
    final tablesRoute = TablesRoute(database);
    final dataRoute = DataRoute(database);
    final queryRoute = QueryRoute(database);
    final schemaRoute = SchemaRoute(database);

    final router = Router();

    // API routes
    router.get('/api/tables', (Request request) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }
      return await tablesRoute.listTables();
    });

    router.get('/api/tables/<tableName>', (Request request, String tableName) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }
      return await tablesRoute.getTableInfo(tableName);
    });

    router.get('/api/tables/<tableName>/data', (Request request, String tableName) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }

      final params = request.url.queryParameters;
      final page = params['page'] != null ? int.tryParse(params['page']!) : null;
      final pageSize = params['pageSize'] != null ? int.tryParse(params['pageSize']!) : null;
      final search = params['search'];
      final sortBy = params['sortBy'];
      final sortDesc = params['sortDesc'] == 'true';

      return await dataRoute.getTableData(
        tableName,
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        sortDesc: sortDesc,
      );
    });

    router.post('/api/tables/<tableName>/data', (Request request, String tableName) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      return await dataRoute.insertRow(tableName, data);
    });

    router.put('/api/tables/<tableName>/data/<id>', (Request request, String tableName, String id) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // Try to determine the primary key column
      final tableInfo = await database.rawQuery("PRAGMA table_info('$tableName')");
      String pkColumn = 'ID';
      try {
        final pkRow = tableInfo.firstWhere(
          (row) => (row['pk'] as int) == 1,
        );
        pkColumn = pkRow['name'] as String;
      } catch (e) {
        // Use default 'ID' if no primary key found
      }

      return await dataRoute.updateRow(tableName, pkColumn, id, data);
    });

    router.delete('/api/tables/<tableName>/data/<id>', (Request request, String tableName, String id) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }

      // Try to determine the primary key column
      final tableInfo = await database.rawQuery("PRAGMA table_info('$tableName')");
      String pkColumn = 'ID';
      try {
        final pkRow = tableInfo.firstWhere(
          (row) => (row['pk'] as int) == 1,
        );
        pkColumn = pkRow['name'] as String;
      } catch (e) {
        // Use default 'ID' if no primary key found
      }

      return await dataRoute.deleteRow(tableName, pkColumn, id);
    });

    router.post('/api/query', (Request request) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final sql = data['sql'] as String;
      final args = data['args'] as List<dynamic>?;

      return await queryRoute.executeQuery(sql, args: args);
    });

    router.get('/api/schema/<tableName>', (Request request, String tableName) async {
      if (!authHandler.isAuthenticated(request)) {
        return Response.forbidden('Authentication required');
      }
      return await schemaRoute.getTableSchema(request, tableName);
    });

    // Serve static files (web UI)
    router.get('/', (Request request) {
      return Response.ok(_getWebUIHtml(), headers: {'Content-Type': 'text/html'});
    });

    // Apply middleware
    final handler = Pipeline()
        .addMiddleware(corsHandler)
        .addMiddleware(authHandler.middleware)
        .addHandler(router);

    // Stop existing server if running
    if (_server != null) {
      await stop();
    }

    // Try to start server, handle port conflicts
    int actualPort = port;
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      try {
        _server = await shelf_io.serve(
          handler,
          InternetAddress.loopbackIPv4,
          actualPort,
        );
        break; // Success
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 48 || e.message.contains('Address already in use')) {
          if (attempts < maxAttempts - 1) {
            actualPort++;
            attempts++;
            print('Port $port is in use, trying port $actualPort...');
            continue;
          } else {
            throw Exception(
              'Port $port is already in use. '
              'Please stop the existing server or use a different port.\n'
              'You can stop the existing server with: lsof -ti:$port | xargs kill'
            );
          }
        } else {
          rethrow;
        }
      }
    }

    if (_server == null) {
      throw Exception('Failed to start server after $maxAttempts attempts');
    }

    print('✓ Web UI server started at http://localhost:$actualPort');
    if (actualPort != port) {
      print('  (Requested port $port was in use, using port $actualPort instead)');
    }
    if (password != null && password.isNotEmpty) {
      print('✓ Password protection enabled. Use ?password=$password in URL');
    }
  }

  /// Stop the web UI server
  static Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      print('Web UI server stopped');
    }
  }

  /// Get the web UI HTML
  static String _getWebUIHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQLite ORM Database Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            color: #333;
            height: 100vh;
            overflow: hidden;
        }
        .app-layout {
            display: flex;
            height: 100vh;
            flex-direction: column;
        }
        header {
            background: #2c3e50;
            color: white;
            padding: 15px 20px;
            flex-shrink: 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { font-size: 22px; font-weight: 600; }
        .main-container {
            display: flex;
            flex: 1;
            overflow: hidden;
        }
        .sidebar {
            width: 280px;
            background: #2c3e50;
            color: white;
            overflow-y: auto;
            flex-shrink: 0;
            border-right: 1px solid #34495e;
        }
        .sidebar-header {
            padding: 20px;
            border-bottom: 1px solid #34495e;
            background: #1a252f;
        }
        .sidebar-header h2 {
            font-size: 16px;
            font-weight: 600;
            color: #ecf0f1;
        }
        .table-list {
            padding: 10px 0;
        }
        .table-item {
            padding: 12px 20px;
            cursor: pointer;
            transition: all 0.2s;
            border-left: 3px solid transparent;
            color: #ecf0f1;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .table-item:hover {
            background: #34495e;
            border-left-color: #3498db;
        }
        .table-item.active {
            background: #34495e;
            border-left-color: #3498db;
            font-weight: 600;
        }
        .table-item::before {
            content: '📊';
            font-size: 16px;
        }
        .content-area {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .tab {
            padding: 10px 20px;
            background: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .tab.active {
            background: #3498db;
            color: white;
            border-color: #3498db;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
        .data-grid {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow-x: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
        }
        .query-editor {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        textarea {
            width: 100%;
            min-height: 200px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
        }
        button {
            padding: 10px 20px;
            background: #3498db;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            margin-top: 10px;
        }
        button:hover {
            background: #2980b9;
        }
        .error {
            background: #e74c3c;
            color: white;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .success {
            background: #27ae60;
            color: white;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .loading {
            text-align: center;
            padding: 20px;
        }
        .pagination {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 4px;
            flex-wrap: wrap;
            gap: 10px;
        }
        .pagination-info {
            color: #333;
            font-size: 14px;
            font-weight: 500;
        }
        .pagination-controls {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .pagination-btn {
            padding: 8px 12px;
            background: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.2s;
            min-width: 40px;
            color: #333;
        }
        .pagination-btn:hover:not(:disabled) {
            background: #3498db;
            color: white;
            border-color: #3498db;
        }
        .pagination-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            color: #999;
        }
        .pagination-btn.active {
            background: #3498db;
            color: white;
            border-color: #3498db;
        }
        .page-size-selector {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .page-size-selector label {
            font-size: 14px;
            color: #7f8c8d;
            white-space: nowrap;
        }
        .page-size-selector select {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            background: white;
            color: #333;
            cursor: pointer;
            min-width: 80px;
            outline: none;
            transition: border-color 0.2s;
        }
        .page-size-selector select:hover {
            border-color: #3498db;
        }
        .page-size-selector select:focus {
            border-color: #3498db;
            box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
        }
        .pagination-numbers {
            display: flex;
            gap: 4px;
            align-items: center;
        }
    </style>
</head>
<body>
    <div class="app-layout">
        <header>
            <h1>SQLite ORM Database Manager</h1>
        </header>
        
        <div class="main-container">
            <div class="sidebar">
                <div class="sidebar-header">
                    <h2>Database Tables</h2>
                </div>
                <div class="table-list" id="table-list">
                    <div class="loading" style="padding: 20px; text-align: center; color: #95a5a6;">Loading tables...</div>
                </div>
            </div>
            
            <div class="content-area">
                <div class="tabs">
                    <div class="tab active" onclick="showTab('tables')">Table Data</div>
                    <div class="tab" onclick="showTab('query')">SQL Query</div>
                </div>

                <div id="tables-tab" class="tab-content active">
                    <div id="data-view" class="data-grid" style="display: none;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 15px; border-bottom: 1px solid #eee;">
                            <h2 id="table-name" style="color: #2c3e50; margin: 0; font-size: 20px;"></h2>
                            <div class="page-size-selector">
                                <label>Rows per page:</label>
                                <select id="page-size-select" onchange="changePageSize()">
                                    <option value="10">10</option>
                                    <option value="25" selected>25</option>
                                    <option value="50">50</option>
                                    <option value="100">100</option>
                                    <option value="200">200</option>
                                </select>
                            </div>
                        </div>
                        <div id="data-grid"></div>
                        <div id="pagination" style="display: none;"></div>
                    </div>
                    <div id="empty-state" style="text-align: center; padding: 60px 20px; color: #7f8c8d;">
                        <div style="font-size: 48px; margin-bottom: 20px;">📋</div>
                        <h3 style="font-size: 20px; margin-bottom: 10px; color: #34495e;">Select a table from the sidebar</h3>
                        <p>Choose a table from the left sidebar to view its data</p>
                    </div>
                </div>

                <div id="query-tab" class="tab-content">
                    <div class="query-editor">
                        <h2>SQL Query Editor</h2>
                        <textarea id="sql-query" placeholder="Enter SQL query..."></textarea>
                        <button onclick="executeQuery()">Execute Query</button>
                        <div id="query-result"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentTable = null;
        let currentPage = 1;
        let pageSize = 25;
        let totalPages = 1;
        let totalCount = 0;
        const password = new URLSearchParams(window.location.search).get('password') || '';

        function showTab(tabName) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
            document.getElementById(tabName + '-tab').classList.add('active');
        }

        function getAuthHeaders() {
            return password ? {'x-password': password} : {};
        }

        async function loadTables() {
            try {
                const response = await fetch('/api/tables', { headers: getAuthHeaders() });
                if (!response.ok) {
                    if (response.status === 403) {
                        document.getElementById('table-list').innerHTML = 
                            '<div style="padding: 20px; color: #e74c3c;">Authentication required. Add ?password=YOUR_PASSWORD to URL</div>';
                        return;
                    }
                    throw new Error('Failed to load tables');
                }
                const data = await response.json();
                const list = document.getElementById('table-list');
                
                if (data.tables && data.tables.length > 0) {
                    list.innerHTML = data.tables.map(table => 
                        \`<div class="table-item" onclick="loadTableData('\${table.name}')" id="table-\${table.name}">
                            <span>\${table.name}</span>
                        </div>\`
                    ).join('');
                } else {
                    list.innerHTML = '<div style="padding: 20px; text-align: center; color: #95a5a6;">No tables found</div>';
                }
            } catch (error) {
                document.getElementById('table-list').innerHTML = 
                    \`<div style="padding: 20px; color: #e74c3c;">Error: \${error.message}</div>\`;
            }
        }

        async function loadTableData(tableName, page = 1) {
            currentTable = tableName;
            currentPage = page;
            
            // Update active state in sidebar
            document.querySelectorAll('.table-item').forEach(item => {
                item.classList.remove('active');
            });
            const activeItem = document.getElementById(\`table-\${tableName}\`);
            if (activeItem) {
                activeItem.classList.add('active');
            }
            
            // Update content area
            document.getElementById('table-name').textContent = tableName;
            document.getElementById('data-view').style.display = 'block';
            document.getElementById('empty-state').style.display = 'none';
            document.getElementById('data-grid').innerHTML = '<div class="loading">Loading data...</div>';
            document.getElementById('pagination').style.display = 'none';

            try {
                const response = await fetch(
                    \`/api/tables/\${tableName}/data?page=\${page}&pageSize=\${pageSize}\`,
                    { headers: getAuthHeaders() }
                );
                if (!response.ok) throw new Error('Failed to load data');
                
                const data = await response.json();
                totalPages = data.pagination?.totalPages || 1;
                totalCount = data.pagination?.totalCount || 0;
                
                if (data.data && data.data.length > 0) {
                    const columns = Object.keys(data.data[0]);
                    const rows = data.data.map(row => 
                        \`<tr>\${columns.map(col => \`<td>\${row[col] ?? ''}</td>\`).join('')}</tr>\`
                    ).join('');
                    
                    document.getElementById('data-grid').innerHTML = \`
                        <table>
                            <thead>
                                <tr>\${columns.map(col => \`<th>\${col}</th>\`).join('')}</tr>
                            </thead>
                            <tbody>\${rows}</tbody>
                        </table>
                    \`;
                    
                    // Always render pagination when we have data
                    renderPagination();
                } else {
                    document.getElementById('data-grid').innerHTML = '<div style="text-align: center; padding: 40px; color: #7f8c8d;">No data found in this table</div>';
                    totalCount = 0;
                    renderPagination(); // This will hide it since totalCount is 0
                }
            } catch (error) {
                document.getElementById('data-grid').innerHTML = 
                    \`<div class="error">Error: \${error.message}</div>\`;
                document.getElementById('pagination').style.display = 'none';
            }
        }
        
        function renderPagination() {
            if (totalCount === 0) {
                document.getElementById('pagination').style.display = 'none';
                return;
            }
            
            document.getElementById('pagination').style.display = 'flex';
            
            const startRow = (currentPage - 1) * pageSize + 1;
            const endRow = Math.min(currentPage * pageSize, totalCount);
            
            let paginationHTML = \`
                <div class="pagination-info">
                    Showing \${startRow} to \${endRow} of \${totalCount} rows
                </div>
            \`;
            
            // Only show page controls if there's more than 1 page
            if (totalPages > 1) {
                paginationHTML += '<div class="pagination-controls">';
                
                // Previous button
                paginationHTML += \`
                    <button class="pagination-btn" onclick="goToPage(\${currentPage - 1})" \${currentPage === 1 ? 'disabled' : ''}>
                        ‹ Previous
                    </button>
                \`;
                
                // Page numbers
                const pageNumbers = getPageNumbers(currentPage, totalPages);
                paginationHTML += '<div class="pagination-numbers">';
                
                let prevPage = 0;
                pageNumbers.forEach(pageNum => {
                    // Add ellipsis if there's a gap
                    if (pageNum - prevPage > 1) {
                        paginationHTML += '<span style="padding: 0 4px; color: #7f8c8d;">...</span>';
                    }
                    
                    paginationHTML += \`
                        <button class="pagination-btn \${pageNum === currentPage ? 'active' : ''}" 
                                onclick="goToPage(\${pageNum})">
                            \${pageNum}
                        </button>
                    \`;
                    prevPage = pageNum;
                });
                
                paginationHTML += '</div>';
                
                // Next button
                paginationHTML += \`
                    <button class="pagination-btn" onclick="goToPage(\${currentPage + 1})" \${currentPage === totalPages ? 'disabled' : ''}>
                        Next ›
                    </button>
                \`;
                
                paginationHTML += '</div>';
            }
            
            document.getElementById('pagination').innerHTML = paginationHTML;
        }
        
        function getPageNumbers(current, total) {
            const delta = 2; // Number of pages to show on each side of current page
            const pages = [];
            
            if (total <= 7) {
                // Show all pages if total is small
                for (let i = 1; i <= total; i++) {
                    pages.push(i);
                }
            } else {
                // Always show first page
                pages.push(1);
                
                // Calculate start and end of page range around current
                let start = Math.max(2, current - delta);
                let end = Math.min(total - 1, current + delta);
                
                // Adjust if we're near the beginning
                if (current <= delta + 1) {
                    end = Math.min(5, total - 1);
                }
                
                // Adjust if we're near the end
                if (current >= total - delta) {
                    start = Math.max(2, total - 4);
                }
                
                // Add ellipsis if needed
                if (start > 2) {
                    // Don't add ellipsis, just skip to start
                }
                
                // Add page numbers in range
                for (let i = start; i <= end; i++) {
                    if (i !== 1 && i !== total) {
                        pages.push(i);
                    }
                }
                
                // Always show last page
                if (total > 1) {
                    pages.push(total);
                }
            }
            
            return pages;
        }
        
        function goToPage(page) {
            if (page < 1 || page > totalPages || page === currentPage) return;
            loadTableData(currentTable, page);
            // Scroll to top of data view
            document.getElementById('data-view').scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
        
        function changePageSize() {
            const newPageSize = parseInt(document.getElementById('page-size-select').value);
            pageSize = newPageSize;
            currentPage = 1; // Reset to first page
            if (currentTable) {
                loadTableData(currentTable, 1);
            }
        }

        async function executeQuery() {
            const sql = document.getElementById('sql-query').value.trim();
            if (!sql) {
                alert('Please enter a SQL query');
                return;
            }

            const resultDiv = document.getElementById('query-result');
            resultDiv.innerHTML = '<div class="loading">Executing query...</div>';

            try {
                const response = await fetch('/api/query', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        ...getAuthHeaders()
                    },
                    body: JSON.stringify({ sql: sql })
                });

                const data = await response.json();
                
                if (data.success) {
                    if (data.data) {
                        const columns = Object.keys(data.data[0] || {});
                        const rows = data.data.map(row => 
                            \`<tr>\${columns.map(col => \`<td>\${row[col] ?? ''}</td>\`).join('')}</tr>\`
                        ).join('');
                        
                        resultDiv.innerHTML = \`
                            <div class="success">Query executed successfully</div>
                            <table style="margin-top: 10px;">
                                <thead>
                                    <tr>\${columns.map(col => \`<th>\${col}</th>\`).join('')}</tr>
                                </thead>
                                <tbody>\${rows}</tbody>
                            </table>
                            <p>Rows returned: \${data.rowCount || 0}</p>
                        \`;
                    } else {
                        resultDiv.innerHTML = \`
                            <div class="success">Query executed successfully</div>
                            <p>Affected rows: \${data.affectedRows || data.id || 0}</p>
                        \`;
                    }
                } else {
                    resultDiv.innerHTML = \`<div class="error">Error: \${data.error}</div>\`;
                }
            } catch (error) {
                resultDiv.innerHTML = \`<div class="error">Error: \${error.message}</div>\`;
            }
        }

        // Load tables on page load
        loadTables();
    </script>
</body>
</html>
''';
  }
}

