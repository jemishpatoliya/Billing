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
      invoice_no TEXT UNIQUE,                -- 015
      date TEXT,                   -- 05-06-2025
      your_firm TEXT,                 -- RUDRA ENTERPRISE
      your_firm_address TEXT,         -- 199, Sneh Milan Soc...

      buyer_name TEXT,               -- AB GLOW SIGN (M/s)
      buyer_address TEXT,            -- First Floor, Plot No...
      place_of_supply TEXT,          -- 24 - Gujarat, Surat...

      gstin_supplier TEXT,           -- 24AHHPU2550P1ZU
      gstin_buyer TEXT,              -- 24BROPG9981J1Z2

      po_number TEXT,                -- Optional
      mobile_no TEXT,                -- Optional

      product_details TEXT,          -- JSON String (S.No., Product Name, HSN, Rate, Qty, Amount)
  
      subtotal REAL,                 -- 41490
      cgst REAL,                     -- 3734
      sgst REAL,                     -- 3734
      total_gst REAL,               -- 7468
      total REAL,                   -- 48958
      rounded_total REAL,           -- 48958.00
      total_in_words TEXT,          -- Forty Eight Thousand...

      bank_name TEXT,               -- HDFC/Axis Bank
      account_number TEXT,          -- 99997878012143
      ifsc_code TEXT,               -- HDFC0001703

      transport TEXT,               -- Optional
      terms_conditions TEXT,        -- JSON or Text 
      jurisdiction TEXT,            -- Surat
      signature TEXT,                -- Authorised Signatory
      hsnSac TEXT,   -- new field
      mm TEXT        -- new field
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
      final user = UserModel.fromJson(result.first);

      // 👇 Check if user is Inactive
      if (user.status?.toLowerCase() == 'inactive') {
        throw Exception('Your account is inactive. Please contact admin.');
      }

      return user;
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
    int updated = await _db.update(
      'invoices',
      invoice.toJson(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    print('Rows updated: $updated');
  }

  Future<void> deleteInvoice(int id) async {
    await _db.delete(
      'invoices', // Table name
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> deleteUser(int id) async {
    await _db.delete('users', where: 'id = ?', whereArgs: [id]);
  }


}
