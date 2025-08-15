import 'dart:convert';

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
      mm TEXT,        -- new field
      paid_amount REAL,
      unpaid_amount REAL,
      size TEXT,
      isGst INTEGER DEFAULT 0,        -- 0 = false, 1 = true
      isOnline INTEGER DEFAULT 0      
      );
    ''');

    await _db.execute('''
    CREATE TABLE IF NOT EXISTS transport (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_no TEXT,
  from_location TEXT,
  to_location TEXT,
  cost REAL,
  summary TEXT
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
  Future<InvoiceModel?> getLastInvoice() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'invoices',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return InvoiceModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getNextInvoiceNumberForToday() async {
    final today = DateTime.now();
    final dateStr = "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

    final result = await _db.rawQuery('''
    SELECT COUNT(*) as count FROM invoices 
    WHERE invoice_no LIKE 'INV-$dateStr%'
  ''');

    int count = (result.first['count'] as int?) ?? 0;
    return count + 1;
  }


  Future<List<Map<String, dynamic>>> getAllCustomersFromInvoices({
    String? name,
    String? mobile,
    String? poNumber,
  }) async {
    String whereClause = '';
    List<String> whereArgs = [];

    if (name != null && name.isNotEmpty) {
      whereClause += 'buyer_name LIKE ?';
      whereArgs.add('%$name%');
    }

    if (mobile != null && mobile.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'mobile_no LIKE ?';
      whereArgs.add('%$mobile%');
    }

    if (poNumber != null && poNumber.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'po_number LIKE ?';
      whereArgs.add('%$poNumber%');
    }

    final result = await _db.rawQuery('''
    SELECT 
      buyer_name,
      buyer_address,
      gstin_buyer,
      mobile_no,
      po_number,
      MAX(invoice_no) AS invoice_no,
      MAX(date) AS invoice_date,   -- This is saved invoice date
      SUM(total) AS total_amount,
      SUM(paid_amount) AS total_paid,
      SUM(total) - SUM(paid_amount) AS total_unpaid
    FROM invoices
    ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
    GROUP BY buyer_name, buyer_address, gstin_buyer, mobile_no, po_number
    ORDER BY buyer_name ASC
  ''', whereArgs);

    return result;
  }
  Future<List<String>> getAllBuyerNames() async {
    final result = await _db.rawQuery('''
    SELECT DISTINCT buyer_name FROM invoices WHERE buyer_name IS NOT NULL ORDER BY buyer_name
  ''');
    return result.map((e) => e['buyer_name'] as String).toList();
  }

  Future<Map<String, dynamic>?> fetchCustomerByName(String name) async {
    final result = await _db.query(
      'invoices',
      where: 'buyer_name = ?',
      whereArgs: [name],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    // Get all invoices with relevant columns
    final invoices = await _db.query(
      'invoices',
      columns: [
        'product_details',
        'total',
        'paid_amount',
        'unpaid_amount',
        'subtotal',
        'invoice_no',
        'buyer_name',
        'mobile_no',
        'date',
      ],
    );

    List<Map<String, dynamic>> allProducts = [];

    for (var invoice in invoices) {
      final productDetailsJson = invoice['product_details'];
      if (productDetailsJson != null && productDetailsJson is String) {
        try {
          final List<dynamic> productsList = jsonDecode(productDetailsJson);

          for (var prod in productsList) {
            if (prod is Map<String, dynamic>) {
              // Merge product details + invoice-level fields
              Map<String, dynamic> productWithInvoiceData = {
                ...prod,  // all product fields
                'total_invoice': invoice['total'],
                'paid_amount': invoice['paid_amount'],
                'unpaid_amount': invoice['unpaid_amount'],
                'subtotal_invoice': invoice['subtotal'],
                'invoice_no': invoice['invoice_no'],
                'buyer_name': invoice['buyer_name'],
                'mobile_no': invoice['mobile_no'],
                'invoice_date': invoice['date'],
              };
              allProducts.add(productWithInvoiceData);
            }
          }
        } catch (e) {
          print('Error parsing product_details JSON: $e');
        }
      }
    }

    return allProducts;
  }

  // Insert a new transport record
  Future<void> addTransport(Map<String, dynamic> transport) async {
    await _db.insert('transport', transport);
  }

// Fetch all transport records
  Future<List<Map<String, dynamic>>> getAllTransport() async {
    return await _db.query('transport', orderBy: 'id DESC');
  }
  Future<String> generateNextTransportInvoiceNumber() async {
    final result = await _db.rawQuery('SELECT MAX(id) as maxId FROM transport');
    int maxId = (result.first['maxId'] as int?) ?? 0;
    return 'TR-${maxId + 1}'.padLeft(6, '0');  // Example: TR-000001
  }


}
