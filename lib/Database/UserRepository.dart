import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../Model/InvoiceModel.dart';
import '../Model/UserModel.dart';

class UserRepository {
  late Database _db;
  bool _isInitialized = false;
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _db = await databaseFactory.openDatabase('Invoxel.db');

    // User table (keep as is)
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS users (  
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT,
        username TEXT,  
        address TEXT,
        email TEXT,
        number TEXT,
        password TEXT,
        role TEXT,
        status TEXT,
        permissions TEXT
      );
    ''');

    // New invoice table
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        your_firm TEXT,
        customer_name TEXT,
        customer_firm TEXT,
        customer_mobile TEXT,
        customer_address TEXT,
        date TEXT,
        is_gst INTEGER,
        invoice_no TEXT,
        ship_to TEXT,
        transport TEXT,
        product_details TEXT,  -- store JSON string of product rows
        amount REAL,
        discount REAL,
        subtotal REAL,
        tax REAL,
        total REAL,
        paid_amount REAL,
        unpaid_amount REAL,
        gst_number TEXT
      );
    ''');
    _isInitialized = true;
  }

  // User functions
  Future<void> registerUser(UserModel user) async {
    await _db.insert('users', user.toJson());
  }

  Future<UserModel?> loginUser(String email, String password) async {
    final result = await _db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return UserModel.fromJson(result.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final result = await _db.query('users');
    return result.map((row) => UserModel.fromJson(row)).toList();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final result = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return UserModel.fromJson(result.first);
    }
    return null;
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _db.insert('invoices', invoice.toJson());
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    final result = await _db.query('invoices', orderBy: "id DESC");
    return result.map((map) => InvoiceModel.fromMap(map)).toList();
  }
  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _db.update(
      'invoices',
      invoice.toJson(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

}
