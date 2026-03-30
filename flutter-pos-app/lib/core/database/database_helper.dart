import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'flutter_pos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        gst_number TEXT,
        logo_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cashier',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_path TEXT,
        barcode TEXT,
        category TEXT,
        cost_price REAL NOT NULL DEFAULT 0,
        selling_price REAL NOT NULL DEFAULT 0,
        tax_percent REAL NOT NULL DEFAULT 0,
        stock_quantity INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        customer_name TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        amount_paid REAL NOT NULL DEFAULT 0,
        change_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        user_id INTEGER,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 1,
        tax_percent REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE estimations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estimation_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        customer_name TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        user_id INTEGER,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE estimation_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estimation_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 1,
        tax_percent REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (estimation_id) REFERENCES estimations(id)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'name': 'Administrator',
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'is_active': 1,
    });

    // Insert sample products
    await db.insert('products', {
      'name': 'Sample Product A',
      'barcode': '1234567890',
      'category': 'General',
      'cost_price': 50.0,
      'selling_price': 100.0,
      'tax_percent': 18.0,
      'stock_quantity': 100,
    });

    await db.insert('products', {
      'name': 'Sample Product B',
      'barcode': '0987654321',
      'category': 'General',
      'cost_price': 30.0,
      'selling_price': 60.0,
      'tax_percent': 12.0,
      'stock_quantity': 50,
    });
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
