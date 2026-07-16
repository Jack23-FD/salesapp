import 'package:mysql1/mysql1.dart';
import '../models/category.dart' as app_models;
import '../models/item.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class MySqlDatabaseService {
  static final MySqlDatabaseService _instance = MySqlDatabaseService._internal();
  
  factory MySqlDatabaseService() {
    return _instance;
  }
  
  MySqlDatabaseService._internal();
  
  // Database connection settings
  final ConnectionSettings _settings = ConnectionSettings(
    host: 'salesapp.cobuewuouuev.us-east-1.rds.amazonaws.com',
    port: 3306,
    user: 'admin',
    password: 'Tharun12345678*',
    db: 'salesapp',
  );
  
  // Connection pool to reuse connections
  MySqlConnection? _connection;
  DateTime? _lastConnectionTime;
  
  // Query result cache
  final Map<String, _CacheEntry> _queryCache = {};
  
  // Cache duration
  final Duration _cacheDuration = const Duration(minutes: 15);
  
  // Get connection with timeout and retry
  Future<MySqlConnection> get connection async {
    try {
      final now = DateTime.now();
      
      // If connection is older than 15 minutes, refresh it
      if (_connection != null && _lastConnectionTime != null && 
          now.difference(_lastConnectionTime!) > const Duration(minutes: 15)) {
        print('Refreshing old MySQL connection');
        await closeConnection();
      }
      
      if (_connection == null) {
        print('Creating new MySQL connection');
        // Use a shorter timeout to prevent UI freezing
        _connection = await MySqlConnection.connect(_settings)
            .timeout(const Duration(seconds: 3),
                onTimeout: () => throw Exception('Database connection timeout'));
        _lastConnectionTime = now;
      }
      
      // Verify connection is still valid with a simple query - use a very short timeout
      try {
        await _connection!.query('SELECT 1')
            .timeout(const Duration(seconds: 1), 
                onTimeout: () => throw Exception('Connection validation timeout'));
      } catch (e) {
        print('Connection validation failed, creating new connection: $e');
        await closeConnection();
        _connection = await MySqlConnection.connect(_settings)
            .timeout(const Duration(seconds: 3));
        _lastConnectionTime = now;
      }
      
      return _connection!;
    } catch (e) {
      print('Error connecting to database: $e');
      // If connection fails, clear it so we can try again next time
      _connection = null;
      rethrow;
    }
  }
  
  // Close connection
  Future<void> closeConnection() async {
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (e) {
        print('Error closing connection: $e');
      } finally {
        _connection = null;
        _lastConnectionTime = null;
      }
    }
  }
  
  // Execute query with error handling, retry and caching
  Future<Results> safeQuery(String sql, [List<Object?>? params, bool useCache = true]) async {
    final cacheKey = '$sql-${params?.join('-') ?? ''}';
    
    // Return cached result if available and cache is enabled
    if (useCache && _queryCache.containsKey(cacheKey)) {
      final cacheEntry = _queryCache[cacheKey]!;
      if (!cacheEntry.isExpired) {
        print('Using cached result for query: $cacheKey');
        return cacheEntry.results;
      } else {
        // Remove expired cache
        _queryCache.remove(cacheKey);
      }
    }
    
    int retries = 0;
    const maxRetries = 1;
    
    while (retries <= maxRetries) {
      try {
        final conn = await connection;
        final results = await conn.query(sql, params)
            .timeout(const Duration(seconds: 3),
                onTimeout: () => throw Exception('Query timeout'));
        
        // Cache the result if caching is enabled
        if (useCache) {
          _queryCache[cacheKey] = _CacheEntry(results, _cacheDuration);
        }
        
        // Close the connection after successful query
        await closeConnection();
        
        return results;
      } catch (e) {
        print('Query error (attempt ${retries + 1}): $e');
        // If query fails, try to create a new connection for next attempt
        _connection = null;
        retries++;
        
        if (retries > maxRetries) {
          // Make sure connection is closed even on error
          await closeConnection();
          rethrow;
        }
        
        // Wait a bit before retrying
        await Future.delayed(Duration(milliseconds: 200 * retries));
      }
    }
    
    // This should never be reached because of the rethrow above
    throw Exception('Failed to execute query after $maxRetries retries');
  }
  
  // Clear cache
  void clearCache() {
    _queryCache.clear();
  }
  
  // Remove specific cache entry
  void removeCacheEntry(String sql, [List<Object?>? params]) {
    final cacheKey = '$sql-${params?.join('-') ?? ''}';
    _queryCache.remove(cacheKey);
  }
  
  // Get all categories
  Future<List<app_models.Category>> getCategories() async {
    try {
      final results = await safeQuery('SELECT * FROM categories', [], true);
      
      List<app_models.Category> categories = [];
      for (var row in results) {
        try {
          final category = app_models.Category(
            id: row['id'].toString(),
            name: row['name'].toString(),
            description: row['description']?.toString(),
          );
          categories.add(category);
        } catch (e) {
          debugPrint('Error creating category from row: $e');
        }
      }
      
      return categories;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return []; // Return empty list instead of throwing error
    }
  }
  
  // Add a category
  Future<void> addCategory(app_models.Category category) async {
    try {
      final conn = await connection;
      await conn.query(
        'INSERT INTO categories (id, name, description) VALUES (?, ?, ?)',
        [category.id, category.name, category.description]
      );
      await closeConnection();
    } catch (e) {
      debugPrint('Error adding category: $e');
      await closeConnection();
      rethrow;
    }
  }
  
  // Update a category
  Future<void> updateCategory(app_models.Category category) async {
    try {
      final conn = await connection;
      await conn.query(
        'UPDATE categories SET name = ?, description = ? WHERE id = ?',
        [category.name, category.description, category.id]
      );
      await closeConnection();
    } catch (e) {
      debugPrint('Error updating category: $e');
      await closeConnection();
      rethrow;
    }
  }
  
  // Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      final conn = await connection;
      // Delete items in this category first
      await conn.query('DELETE FROM products WHERE categoryId = ?', [id]);
      // Then delete the category
      await conn.query('DELETE FROM categories WHERE id = ?', [id]);
      await closeConnection();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      await closeConnection();
      rethrow;
    }
  }
  
  // Get all products with limit for efficient loading
  Future<List<Item>> getProductsWithLimit(int limit) async {
    try {
      final results = await safeQuery(
        'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category = c.id LIMIT ?',
        [limit]
      );
      
      List<Item> items = [];
      for (var row in results) {
        try {
          final item = Item(
            id: row['id'].toString(),
            name: row['productname'].toString(),
            categoryId: row['category'].toString(),
            barcode: row['barcode']?.toString(),
            price: double.parse(row['price'].toString()),
            createdAt: DateTime.now(),
            type: 'inbound',
            quantity: row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1,
            unit: 'pc',
            categoryName: row['category_name']?.toString(),
          );
          items.add(item);
        } catch (e) {
          debugPrint('Error creating item from row: $e');
        }
      }
      
      return items;
    } catch (e) {
      debugPrint('Error getting products with limit: $e');
      return []; // Return empty list instead of throwing error
    }
  }
  
  // Get remaining products after initial load
  Future<List<Item>> getRemainingProducts(int skip) async {
    try {
      final conn = await connection;
      final results = await conn.query(
        'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category = c.id LIMIT 1000 OFFSET ?',
        [skip]
      );
      
      List<Item> items = [];
      for (var row in results) {
        try {
          final item = Item(
            id: row['id'].toString(),
            name: row['productname'].toString(),
            categoryId: row['category'].toString(),
            barcode: row['barcode']?.toString(),
            price: double.parse(row['price'].toString()),
            createdAt: DateTime.now(),
            type: 'inbound',
            quantity: row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1,
            unit: 'pc',
            categoryName: row['category_name']?.toString(),
          );
          items.add(item);
        } catch (e) {
          debugPrint('Error creating item from row: $e');
        }
      }
      
      return items;
    } catch (e) {
      debugPrint('Error getting remaining products: $e');
      rethrow;
    }
  }

  // Get all products with improved category info
  Future<List<Item>> getAllProducts() async {
    try {
      final conn = await connection;
      final results = await conn.query(
        'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category = c.id'
      );
      
      List<Item> items = [];
      for (var row in results) {
        try {
          final item = Item(
            id: row['id'].toString(),
            name: row['productname'].toString(),
            categoryId: row['category'].toString(),
            barcode: row['barcode']?.toString(),
            price: double.parse(row['price'].toString()),
            createdAt: DateTime.now(),
            type: 'inbound',
            quantity: row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1,
            unit: 'pc',
            categoryName: row['category_name']?.toString(),
          );
          items.add(item);
        } catch (e) {
          debugPrint('Error creating item from row: $e');
        }
      }
      
      return items;
    } catch (e) {
      debugPrint('Error getting products: $e');
      rethrow;
    }
  }
  
  // Get products by category with category name
  Future<List<Item>> getProductsByCategory(String categoryId) async {
    try {
      final conn = await connection;
      final results = await conn.query(
        'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category = c.id WHERE p.category = ?',
        [categoryId]
      );
      
      List<Item> items = [];
      for (var row in results) {
        try {
          final item = Item(
            id: row['id'].toString(),
            name: row['productname'].toString(),
            categoryId: row['category'].toString(),
            barcode: row['barcode']?.toString(),
            price: double.parse(row['price'].toString()),
            createdAt: DateTime.now(),
            type: 'inbound',
            quantity: row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1,
            unit: 'pc',
            categoryName: row['category_name']?.toString(),
          );
          items.add(item);
        } catch (e) {
          debugPrint('Error creating item from row: $e');
        }
      }
      
      return items;
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      rethrow;
    }
  }
  
  // Add a product
  Future<void> addProduct(Item item) async {
    try {
      debugPrint('MySQLDatabaseService: Adding product ${item.id} to database');
      final conn = await connection;
      
      // First check if product already exists by ID
      final existingProducts = await conn.query(
        'SELECT id FROM products WHERE id = ?',
        [item.id]
      );
      
      if (existingProducts.isNotEmpty) {
        debugPrint('MySQLDatabaseService: Product ${item.id} already exists, updating instead');
        await conn.query(
          'UPDATE products SET productname = ?, category = ?, barcode = ?, price = ?, quantity = ? WHERE id = ?',
          [item.name, item.categoryId, item.barcode, item.price, item.quantity, item.id]
        );
        debugPrint('MySQLDatabaseService: Successfully updated product ${item.id}');
      } else {
        // Insert new product
        await conn.query(
          'INSERT INTO products (id, productname, category, barcode, price, quantity) VALUES (?, ?, ?, ?, ?, ?)',
          [item.id, item.name, item.categoryId, item.barcode, item.price, item.quantity]
        );
        debugPrint('MySQLDatabaseService: Successfully inserted product ${item.id}');
      }
      
      // Verify product was added/updated
      final verification = await conn.query(
        'SELECT id FROM products WHERE id = ?',
        [item.id]
      );
      
      if (verification.isEmpty) {
        throw Exception('Product was not found after adding/updating');
      }
      
      debugPrint('MySQLDatabaseService: Product ${item.id} verified in database');
    } catch (e) {
      debugPrint('MySQLDatabaseService: Error adding/updating product: $e');
      rethrow;
    }
  }
  
  // Update a product
  Future<void> updateProduct(Item item) async {
    try {
      final conn = await connection;
      await conn.query(
        'UPDATE products SET productname = ?, category = ?, barcode = ?, price = ?, quantity = ? WHERE id = ?',
        [item.name, item.categoryId, item.barcode, item.price, item.quantity, item.id]
      );
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }
  
  // Update product quantity
  Future<void> updateProductQuantity(String id, int quantity) async {
    try {
      final conn = await connection;
      await conn.query(
        'UPDATE products SET quantity = ? WHERE id = ?',
        [quantity, id]
      );
    } catch (e) {
      debugPrint('Error updating product quantity: $e');
      rethrow;
    }
  }
  
  // Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      final conn = await connection;
      
      // First verify the product exists
      final productExists = await conn.query(
        'SELECT id FROM products WHERE id = ?',
        [id]
      );
      
      if (productExists.isEmpty) {
        debugPrint('Product $id not found, nothing to delete');
        return;
      }
      
      // Start transaction to ensure all operations complete together
      await conn.query('START TRANSACTION');
      
      try {
        // Delete related transactions first
        await conn.query('DELETE FROM inbound_transactions WHERE item_id = ?', [id]);
        await conn.query('DELETE FROM outbound_transactions WHERE item_id = ?', [id]);
        
        // Delete the product
        await conn.query('DELETE FROM products WHERE id = ?', [id]);
        
        // Commit the transaction
        await conn.query('COMMIT');
        
        // Verify the product was deleted
        final verification = await conn.query(
          'SELECT id FROM products WHERE id = ?',
          [id]
        );
        
        if (verification.isNotEmpty) {
          debugPrint('WARNING: Product $id still exists after deletion attempt');
        } else {
          debugPrint('Product $id and its transactions successfully deleted');
        }
      } catch (e) {
        // Roll back on error
        await conn.query('ROLLBACK');
        debugPrint('Error in transaction, rolling back: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }
  
  // Database initialization - you can call this when app starts
  Future<void> initializeDatabase() async {
    try {
      final conn = await connection;
      
      debugPrint('Starting database initialization...');
      
      // Create categories table if it doesn't exist
      await conn.query('''
        CREATE TABLE IF NOT EXISTS categories (
          id VARCHAR(50) PRIMARY KEY,
          name VARCHAR(100) NOT NULL,
          description TEXT
        )
      ''');
      debugPrint('Categories table ready');
      
      // Create products table if it doesn't exist
      await conn.query('''
        CREATE TABLE IF NOT EXISTS products (
          id VARCHAR(50) PRIMARY KEY,
          productname VARCHAR(100) NOT NULL,
          category VARCHAR(50) NOT NULL,
          barcode VARCHAR(100),
          price DECIMAL(10,2) NOT NULL,
          quantity INT NOT NULL DEFAULT 1
        )
      ''');
      debugPrint('Products table ready');
      
      // First check if the inbound_transactions table exists
      final inboundTableExists = await conn.query(
        "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'inbound_transactions'"
      );
      
      final outboundTableExists = await conn.query(
        "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'outbound_transactions'"
      );
      
      // If tables don't exist, create them
      if (inboundTableExists.first['count'] == 0) {
        debugPrint('Creating inbound_transactions table...');
        // Create inbound transactions table
        await conn.query('''
          CREATE TABLE IF NOT EXISTS inbound_transactions (
            id VARCHAR(50) PRIMARY KEY,
            item_id VARCHAR(50) NOT NULL,
            quantity INT NOT NULL,
            transaction_date DATETIME NOT NULL,
            FOREIGN KEY (item_id) REFERENCES products(id) ON DELETE CASCADE
          )
        ''');
        debugPrint('Inbound transactions table created successfully');
      } else {
        debugPrint('Inbound transactions table already exists');
      }
      
      if (outboundTableExists.first['count'] == 0) {
        debugPrint('Creating outbound_transactions table...');
        // Create outbound transactions table
        await conn.query('''
          CREATE TABLE IF NOT EXISTS outbound_transactions (
            id VARCHAR(50) PRIMARY KEY,
            item_id VARCHAR(50) NOT NULL,
            quantity INT NOT NULL,
            transaction_date DATETIME NOT NULL,
            FOREIGN KEY (item_id) REFERENCES products(id) ON DELETE CASCADE
          )
        ''');
        debugPrint('Outbound transactions table created successfully');
      } else {
        debugPrint('Outbound transactions table already exists');
      }
      
      // Migrate data from prize to price if needed
      await _migrateColumnIfNeeded();
      
      // Add quantity column if it doesn't exist
      await _addQuantityColumnIfNeeded();
      
      debugPrint('Database initialization complete');
      
      // Print summary of database tables
      final tableCountsResult = await conn.query(
        "SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.tables WHERE table_schema = DATABASE()"
      );
      
      debugPrint('Database tables summary:');
      for (var row in tableCountsResult) {
        debugPrint('Table ${row['TABLE_NAME']}: ~${row['TABLE_ROWS']} rows');
      }
      
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
  
  // Helper method to migrate data from prize to price if needed
  Future<void> _migrateColumnIfNeeded() async {
    try {
      final conn = await connection;
      
      // Check if prize column exists
      final columns = await conn.query("SHOW COLUMNS FROM products LIKE 'prize'");
      
      if (columns.isNotEmpty) {
        debugPrint('Prize column exists, migrating data to price column...');
        
        // Add price column if it doesn't exist
        await conn.query("ALTER TABLE products ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) NOT NULL DEFAULT 0.0");
        
        // Copy data from prize to price
        await conn.query("UPDATE products SET price = prize");
        
        // Drop prize column
        await conn.query("ALTER TABLE products DROP COLUMN prize");
        
        debugPrint('Migration completed successfully');
      } else {
        debugPrint('No migration needed, price column already exists');
      }
    } catch (e) {
      debugPrint('Error migrating from prize to price: $e');
    }
  }
  
  // Helper method to add quantity column if needed
  Future<void> _addQuantityColumnIfNeeded() async {
    try {
      final conn = await connection;
      
      // Check if quantity column exists
      final columns = await conn.query("SHOW COLUMNS FROM products LIKE 'quantity'");
      
      if (columns.isEmpty) {
        debugPrint('Quantity column does not exist, adding it...');
        
        // Add quantity column
        await conn.query("ALTER TABLE products ADD COLUMN quantity INT NOT NULL DEFAULT 1");
        
        debugPrint('Quantity column added successfully');
      } else {
        debugPrint('Quantity column already exists');
      }
    } catch (e) {
      debugPrint('Error adding quantity column: $e');
    }
  }
  
  // Add inbound transaction record
  Future<void> addInboundTransaction(String id, String itemId, int quantity, DateTime date) async {
    try {
      final conn = await connection;
      
      // Format date properly for MySQL
      final formattedDate = date.toIso8601String().split('T').join(' ').split('.')[0];
      
      // Verify the product exists first
      final productCheck = await conn.query(
        'SELECT id FROM products WHERE id = ?',
        [itemId]
      );
      
      if (productCheck.isEmpty) {
        throw Exception('Cannot add transaction: Product $itemId does not exist');
      }
      
      // Insert the transaction with explicit date format
      await conn.query(
        'INSERT INTO inbound_transactions (id, item_id, quantity, transaction_date) VALUES (?, ?, ?, ?)',
        [id, itemId, quantity, formattedDate]
      );
      
      debugPrint('Successfully recorded inbound transaction: ID=$id, Product=$itemId, Quantity=$quantity, Date=$formattedDate');
    } catch (e) {
      debugPrint('Error adding inbound transaction: $e');
      rethrow;
    }
  }
  
  // Add outbound transaction record
  Future<void> addOutboundTransaction(String id, String itemId, int quantity, DateTime date) async {
    try {
      final conn = await connection;
      
      // Format date properly for MySQL
      final formattedDate = date.toIso8601String().split('T').join(' ').split('.')[0];
      
      // Verify the product exists first
      final productCheck = await conn.query(
        'SELECT id FROM products WHERE id = ?',
        [itemId]
      );
      
      if (productCheck.isEmpty) {
        throw Exception('Cannot add outbound transaction: Product $itemId does not exist');
      }
      
      // Insert the transaction with explicit date format
      await conn.query(
        'INSERT INTO outbound_transactions (id, item_id, quantity, transaction_date) VALUES (?, ?, ?, ?)',
        [id, itemId, quantity, formattedDate]
      );
      
      debugPrint('Successfully recorded outbound transaction: ID=$id, Product=$itemId, Quantity=$quantity, Date=$formattedDate');
    } catch (e) {
      debugPrint('Error adding outbound transaction: $e');
      rethrow;
    }
  }
  
  // Get total inbound quantity for a date
  Future<int> getTotalInboundQuantityByDate(DateTime date) async {
    MySqlConnection? tempConn;
    try {
      // Create a fresh connection for this critical query
      tempConn = await MySqlConnection.connect(_settings)
          .timeout(const Duration(seconds: 5),
              onTimeout: () => throw Exception('Database connection timeout'));
      
      // Format the date properly for MySQL comparison
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      // Execute the query directly with the new connection
      final results = await tempConn.query(
        '''
        SELECT SUM(quantity) as total 
        FROM inbound_transactions 
        WHERE DATE(transaction_date) = ?
        ''',
        [formattedDate]
      );
      
      // Debug the raw query results
      debugPrint('MySQLDatabaseService: Raw inbound query result: ${results.first}');
      
      final total = results.first['total'];
      // Convert double to int safely
      int result = 0;
      if (total != null) {
        if (total is int) {
          result = total;
        } else if (total is double) {
          result = total.toInt(); // Convert double to int
        } else {
          // Try to parse as double first, then convert to int
          try {
            result = double.parse(total.toString()).toInt();
          } catch (e) {
            debugPrint('MySQLDatabaseService: Error parsing inbound quantity: $e');
          }
        }
      }
      
      // Verify if the result is 0 but there are actually records
      if (result == 0) {
        // Try a different approach: count the records instead of summing
        final countResults = await tempConn.query(
          '''
          SELECT COUNT(*) as record_count 
          FROM inbound_transactions 
          WHERE DATE(transaction_date) = ?
          ''',
          [formattedDate]
        );
        
        final recordCount = countResults.first['record_count'];
        if (recordCount != null && (recordCount is int && recordCount > 0)) {
          debugPrint('MySQLDatabaseService: Found $recordCount inbound records but sum was 0, checking raw data');
          
          // Get actual records to debug
          final rawRecords = await tempConn.query(
            '''
            SELECT item_id, quantity, transaction_date 
            FROM inbound_transactions 
            WHERE DATE(transaction_date) = ?
            LIMIT 10
            ''',
            [formattedDate]
          );
          
          debugPrint('MySQLDatabaseService: Sample inbound records for $formattedDate:');
          for (var row in rawRecords) {
            debugPrint('  Item: ${row['item_id']}, Quantity: ${row['quantity']}, Date: ${row['transaction_date']}');
            // Add quantities manually as a fallback
            if (row['quantity'] != null) {
              try {
                int qty = 0;
                if (row['quantity'] is int) {
                  qty = row['quantity'] as int;
                } else if (row['quantity'] is double) {
                  qty = (row['quantity'] as double).toInt();
                } else {
                  qty = int.parse(row['quantity'].toString());
                }
                result += qty;
              } catch (e) {
                debugPrint('Error parsing quantity: $e');
              }
            }
          }
          debugPrint('MySQLDatabaseService: Manual calculation found total: $result');
        }
      }
      
      debugPrint('MySQLDatabaseService: Final inbound quantity for $formattedDate: $result');
      return result;
    } catch (e) {
      debugPrint('MySQLDatabaseService: Error getting inbound quantity: $e');
      return 0;
    } finally {
      // Always close the temporary connection
      if (tempConn != null) {
        try {
          await tempConn.close();
        } catch (e) {
          debugPrint('Error closing temp connection: $e');
        }
      }
    }
  }
  
  // Get total outbound quantity for a date
  Future<int> getTotalOutboundQuantityByDate(DateTime date) async {
    try {
      final conn = await connection;
      // Format the date properly for MySQL comparison
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final results = await conn.query(
        '''
        SELECT SUM(quantity) as total 
        FROM outbound_transactions 
        WHERE DATE(transaction_date) = ?
        ''',
        [formattedDate]
      );
      
      // Debug the raw query results
      debugPrint('MySQLDatabaseService: Raw outbound query result: ${results.first}');
      
      final total = results.first['total'];
      // Convert double to int safely
      int result = 0;
      if (total != null) {
        if (total is int) {
          result = total;
        } else if (total is double) {
          result = total.toInt(); // Convert double to int
        } else {
          // Try to parse as double first, then convert to int
          try {
            result = double.parse(total.toString()).toInt();
          } catch (e) {
            debugPrint('MySQLDatabaseService: Error parsing total quantity: $e');
          }
        }
      }
      debugPrint('MySQLDatabaseService: Total outbound quantity for $formattedDate: $result');
      return result;
    } catch (e) {
      debugPrint('MySQLDatabaseService: Error getting outbound quantity: $e');
      return 0;
    }
  }
  
  // Get unique categories with inbound transactions on a date
  Future<int> getInboundCategoriesCountByDate(DateTime date) async {
    MySqlConnection? tempConn;
    try {
      // Create a fresh connection for this critical query
      tempConn = await MySqlConnection.connect(_settings)
          .timeout(const Duration(seconds: 5),
              onTimeout: () => throw Exception('Database connection timeout'));
      
      // Format the date properly for MySQL comparison
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final results = await tempConn.query('''
        SELECT COUNT(DISTINCT p.category) as count 
        FROM inbound_transactions t
        JOIN products p ON t.item_id = p.id
        WHERE DATE(t.transaction_date) = ?
      ''', [formattedDate]);
      
      final count = results.first['count'];
      int result = count != null ? int.parse(count.toString()) : 0;
      
      // If the count is 0, try to get a list of distinct categories to verify
      if (result == 0) {
        final distinctResults = await tempConn.query('''
          SELECT DISTINCT p.category, p.name as category_name 
          FROM inbound_transactions t
          JOIN products p ON t.item_id = p.id
          WHERE DATE(t.transaction_date) = ?
        ''', [formattedDate]);
        
        if (distinctResults.isNotEmpty) {
          debugPrint('MySQLDatabaseService: Found ${distinctResults.length} distinct categories but count was 0');
          result = distinctResults.length;
          
          // Debug the categories we found
          for (var row in distinctResults) {
            debugPrint('  Category: ${row['category']}, Name: ${row['category_name']}');
          }
        }
      }
      
      debugPrint('MySQLDatabaseService: Inbound categories count for $formattedDate: $result');
      return result;
    } catch (e) {
      debugPrint('Error getting inbound categories count: $e');
      return 0;
    } finally {
      // Always close the temporary connection
      if (tempConn != null) {
        try {
          await tempConn.close();
        } catch (e) {
          debugPrint('Error closing temp connection: $e');
        }
      }
    }
  }
  
  // Get unique categories with outbound transactions on a date
  Future<int> getOutboundCategoriesCountByDate(DateTime date) async {
    try {
      final conn = await connection;
      // Format the date properly for MySQL comparison
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final results = await conn.query('''
        SELECT COUNT(DISTINCT p.category) as count 
        FROM outbound_transactions t
        JOIN products p ON t.item_id = p.id
        WHERE DATE(t.transaction_date) = ?
      ''', [formattedDate]);
      
      final count = results.first['count'];
      return count != null ? int.parse(count.toString()) : 0;
    } catch (e) {
      debugPrint('Error getting outbound categories count: $e');
      return 0;
    }
  }
  
  // Get total inbound transaction value for a date
  Future<double> getTotalInboundValueByDate(DateTime date) async {
    MySqlConnection? tempConn;
    try {
      // Create a fresh connection for this critical query
      tempConn = await MySqlConnection.connect(_settings)
          .timeout(const Duration(seconds: 5),
              onTimeout: () => throw Exception('Database connection timeout'));
      
      // Format the date properly for MySQL comparison
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final results = await tempConn.query('''
        SELECT SUM(t.quantity * p.price) as total_value
        FROM inbound_transactions t
        JOIN products p ON t.item_id = p.id
        WHERE DATE(t.transaction_date) = ?
      ''', [formattedDate]);
      
      final totalValue = results.first['total_value'];
      double result = totalValue != null ? double.parse(totalValue.toString()) : 0.0;
      
      // If the value is 0, try to calculate it manually from records
      if (result == 0) {
        final rawRecords = await tempConn.query('''
          SELECT t.quantity, p.price, p.productname
          FROM inbound_transactions t
          JOIN products p ON t.item_id = p.id
          WHERE DATE(t.transaction_date) = ?
        ''', [formattedDate]);
        
        if (rawRecords.isNotEmpty) {
          debugPrint('MySQLDatabaseService: Found ${rawRecords.length} inbound records but value was 0, calculating manually');
          
          double manualTotal = 0.0;
          for (var row in rawRecords) {
            try {
              double price = row['price'] is double ? row['price'] as double : double.parse(row['price'].toString());
              int qty = row['quantity'] is int ? row['quantity'] as int : int.parse(row['quantity'].toString());
              double itemValue = price * qty;
              manualTotal += itemValue;
              debugPrint('  Product: ${row['productname']}, Qty: $qty, Price: $price, Value: $itemValue');
            } catch (e) {
              debugPrint('Error calculating item value: $e');
            }
          }
          
          result = manualTotal;
          debugPrint('MySQLDatabaseService: Manual calculation found total value: $result');
        }
      }
      
      debugPrint('MySQLDatabaseService: Final inbound value for $formattedDate: $result');
      return result;
    } catch (e) {
      debugPrint('Error getting inbound value: $e');
      return 0.0;
    } finally {
      // Always close the temporary connection
      if (tempConn != null) {
        try {
          await tempConn.close();
        } catch (e) {
          debugPrint('Error closing temp connection: $e');
        }
      }
    }
  }
  
  // Get total outbound transaction value for a date
  Future<double> getTotalOutboundValueByDate(DateTime date) async {
    try {
      final conn = await connection;
      // Format the date properly for MySQL comparison
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final results = await conn.query('''
        SELECT SUM(t.quantity * p.price) as total_value
        FROM outbound_transactions t
        JOIN products p ON t.item_id = p.id
        WHERE DATE(t.transaction_date) = ?
      ''', [formattedDate]);
      
      final totalValue = results.first['total_value'];
      return totalValue != null ? double.parse(totalValue.toString()) : 0.0;
    } catch (e) {
      debugPrint('Error getting outbound value: $e');
      return 0.0;
    }
  }
  
  // Migrate existing products to create inbound transaction records
  Future<void> migrateExistingProductsToTransactions() async {
    try {
      final conn = await connection;
      
      // Find products with no inbound transactions
      final productsWithNoInbound = await conn.query('''
        SELECT p.* FROM products p
        LEFT JOIN (
          SELECT DISTINCT item_id FROM inbound_transactions
        ) t ON p.id = t.item_id
        WHERE t.item_id IS NULL
      ''');
      
      debugPrint('Found ${productsWithNoInbound.length} products with no inbound transactions');
      
      // Only create transactions for products that don't have any
      if (productsWithNoInbound.isEmpty) {
        debugPrint('All products have transaction records, nothing to migrate');
        return;
      }
      
      // Create inbound transactions only for products that don't have any
      for (var row in productsWithNoInbound) {
        try {
          final productId = row['id'].toString();
          final quantity = row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1;
          
          // Use UUID package for consistency
          final id = const Uuid().v4();
          
          // Format date properly for MySQL
          final now = DateTime.now();
          final formattedDate = now.toIso8601String().split('T').join(' ').split('.')[0];
          
          // Insert the transaction with explicit date format
          await conn.query(
            'INSERT INTO inbound_transactions (id, item_id, quantity, transaction_date) VALUES (?, ?, ?, ?)',
            [id, productId, quantity, formattedDate]
          );
          
          debugPrint('Created inbound transaction for product $productId');
        } catch (e) {
          debugPrint('Error creating transaction for product ${row['id']}: $e');
          // Continue with next product even if this one fails
        }
      }
      
      debugPrint('Successfully migrated ${productsWithNoInbound.length} products to transactions');
    } catch (e) {
      debugPrint('Error migrating products to transactions: $e');
    }
  }
  
  // Fix method to get all products with proper category reference
  Future<List<Item>> getAllProductsWithCategories() async {
    try {
      final conn = await connection;
      final results = await conn.query(
        '''
        SELECT p.*, c.name as category_name
        FROM products p 
        LEFT JOIN categories c ON p.category = c.id
        '''
      );
      
      List<Item> items = [];
      for (var row in results) {
        try {
          final item = Item(
            id: row['id'].toString(),
            name: row['productname'].toString(),
            categoryId: row['category'].toString(),
            barcode: row['barcode']?.toString(),
            price: double.parse(row['price'].toString()),
            createdAt: DateTime.now(),
            type: 'inbound',
            quantity: row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1,
            unit: 'pcs',
            categoryName: row['category_name']?.toString() ?? 'Uncategorized',
          );
          items.add(item);
        } catch (e) {
          debugPrint('Error creating item from row: $e');
        }
      }
      
      return items;
    } catch (e) {
      debugPrint('Error getting products with categories: $e');
      return [];
    }
  }
  
  // Debug method to inspect today's transactions
  Future<void> debugTodaysTransactions() async {
    try {
      final conn = await connection;
      final now = DateTime.now();
      final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      debugPrint('========= DEBUGGING TODAY\'S TRANSACTIONS ($todayDate) =========');
      
      // Check inbound transactions
      final inboundQuery = await conn.query('''
        SELECT t.id, t.item_id, p.productname, t.quantity, t.transaction_date 
        FROM inbound_transactions t
        JOIN products p ON t.item_id = p.id
        WHERE DATE(t.transaction_date) = ?
        ORDER BY t.transaction_date DESC
      ''', [todayDate]);
      
      debugPrint('Found ${inboundQuery.length} inbound transactions today:');
      for (var row in inboundQuery) {
        debugPrint('INBOUND: ID=${row['id']}, Product=${row['productname']}, Quantity=${row['quantity']}, Date=${row['transaction_date']}');
      }
      
      // Check outbound transactions
      final outboundQuery = await conn.query('''
        SELECT t.id, t.item_id, p.productname, t.quantity, t.transaction_date 
        FROM outbound_transactions t
        JOIN products p ON t.item_id = p.id
        WHERE DATE(t.transaction_date) = ?
        ORDER BY t.transaction_date DESC
      ''', [todayDate]);
      
      debugPrint('Found ${outboundQuery.length} outbound transactions today:');
      for (var row in outboundQuery) {
        debugPrint('OUTBOUND: ID=${row['id']}, Product=${row['productname']}, Quantity=${row['quantity']}, Date=${row['transaction_date']}');
      }
      
      // Check if any products were added/updated today but have no transactions
      final productsQuery = await conn.query('''
        SELECT p.id, p.productname, p.quantity, 
               (SELECT COUNT(*) FROM inbound_transactions WHERE item_id = p.id AND DATE(transaction_date) = ?) as inbound_count
        FROM products p
        ORDER BY inbound_count ASC
        LIMIT 10
      ''', [todayDate]);
      
      debugPrint('Recent products with transaction counts:');
      for (var row in productsQuery) {
        debugPrint('PRODUCT: ID=${row['id']}, Name=${row['productname']}, Qty=${row['quantity']}, Inbound Count=${row['inbound_count']}');
      }
      
      debugPrint('======== END TRANSACTION DEBUG ========');
    } catch (e) {
      debugPrint('Error debugging transactions: $e');
    }
  }
  
  // Helper method to run operations with an auto-closing connection
  Future<T> withConnection<T>(Future<T> Function(MySqlConnection conn) operation) async {
    try {
      final conn = await connection;
      final result = await operation(conn);
      await closeConnection();
      return result;
    } catch (e) {
      await closeConnection();
      rethrow;
    }
  }
  
  // Example of using withConnection helper
  Future<bool> doesProductExist(String productId) async {
    return withConnection((conn) async {
      final results = await conn.query(
        'SELECT id FROM products WHERE id = ?',
        [productId]
      );
      
      return results.isNotEmpty;
    });
  }
  
  // Get total products count
  Future<int> getTotalProductCount() async {
    try {
      final conn = await connection;
      final results = await conn.query('SELECT COUNT(*) as count FROM products');
      
      final count = results.first['count'];
      return count != null ? int.parse(count.toString()) : 0;
    } catch (e) {
      debugPrint('Error getting total product count: $e');
      return 0;
    }
  }
  
  // Get total categories count
  Future<int> getTotalCategoryCount() async {
    try {
      final conn = await connection;
      final results = await conn.query('SELECT COUNT(*) as count FROM categories');
      
      final count = results.first['count'];
      return count != null ? int.parse(count.toString()) : 0;
    } catch (e) {
      debugPrint('Error getting total category count: $e');
      return 0;
    }
  }
}

// Cache entry class
class _CacheEntry {
  final Results results;
  final DateTime expirationTime;
  
  _CacheEntry(this.results, Duration duration) 
    : expirationTime = DateTime.now().add(duration);
  
  bool get isExpired => DateTime.now().isAfter(expirationTime);
} 