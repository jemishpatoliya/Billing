import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../Model/InvoiceModel.dart';
import 'package:path_provider/path_provider.dart';
import '../Model/ProductModel.dart';
import '../Model/PurchaseModel.dart';
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

    // ✅ Get a safe folder for the DB
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dbPath = p.join(appDocDir.path, 'Invoxel.db');

    print("📂 Database path: $dbPath");

    _db = await databaseFactory.openDatabase(dbPath); // ✅ Correct

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

    await _db.execute('''
CREATE TABLE IF NOT EXISTS purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,        -- unique row id
  purchase_id TEXT,                             -- unique purchase id
  invoice_no TEXT,                              -- invoice number
  created_at TEXT DEFAULT (datetime('now')),    -- creation timestamp
  company_name TEXT,
  company_address TEXT,
  company_gstin TEXT,
  company_email TEXT,
  
  products TEXT,                                -- JSON string of all products in this purchase
  product_id TEXT,                              -- unique product id
  product_name TEXT,
  hsn_sac TEXT,
  mm TEXT,
  rate REAL,
  colour TEXT,
  colour_code TEXT,
  per TEXT,
  total REAL,
  gst REAL,
  packing_forwarding REAL,

  final_amount REAL,
  dispatch_from TEXT,
  ship_to TEXT,
  pdf_path TEXT,
  skuItems TEXT
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

  Future<int> getNextAvailableSKUNumber() async {
    // Get all purchases ordered by ID (creation order) and find the highest SKU number
    final purchases = await getAllPurchases();
    int maxSkuNumber = 0;
    
    print('🔍 Checking ${purchases.length} purchases for existing SKUs...');
    
    // Sort purchases by ID to ensure proper order
    purchases.sort((a, b) => (a.id ?? '0').compareTo(b.id ?? '0'));
    
    for (var purchase in purchases) {
      if (purchase.skuItems != null) {
        print('📋 Purchase ${purchase.invoiceNo} (ID: ${purchase.id}): ${purchase.skuItems!.length} SKU items');
        
        for (var skuItem in purchase.skuItems!) {
          final sku = skuItem['sku'] as String?;
          if (sku != null && sku.startsWith('SK')) {
            try {
              final skuNumber = int.tryParse(sku.substring(2));
              if (skuNumber != null && skuNumber > maxSkuNumber) {
                maxSkuNumber = skuNumber;
                print('🏆 New highest SKU found: $sku (number: $skuNumber)');
              }
            } catch (e) {
              print('❌ Error parsing SKU: $sku - $e');
            }
          }
        }
      }
    }
    
    final nextNumber = maxSkuNumber + 1;
    print('🎯 Next available SKU number: $nextNumber (current max: $maxSkuNumber)');
    
    return nextNumber;
  }

  Future<int> getNextSKUNumberForPurchase(String purchaseId) async {
    // Get all purchases ordered by ID (creation order)
    final purchases = await getAllPurchases();
    int currentSkuNumber = 1;
    
    // Sort purchases by ID to ensure proper order
    purchases.sort((a, b) => (a.id ?? '0').compareTo(b.id ?? '0'));
    
    // Find the target purchase and calculate SKU number
    for (var purchase in purchases) {
      if (purchase.purchaseId == purchaseId) {
        // Found the target purchase, return the current SKU number
        print('🎯 Found purchase $purchaseId, starting SKU from: $currentSkuNumber');
        return currentSkuNumber;
      }
      
      // Add up SKUs from previous purchases
      if (purchase.products != null) {
        for (var prod in purchase.products!) {
          int qty = prod.qty ?? 0;
          currentSkuNumber += qty;
        }
      }
    }
    
    // If purchase not found, return the next available number
    return await getNextAvailableSKUNumber();
  }

  Future<void> resetAllSKUNumbers() async {
    // Get all purchases ordered by ID (creation order)
    final purchases = await getAllPurchases();
    int currentSkuNumber = 1;
    
    print('🔄 Resetting all SKU numbers across ${purchases.length} purchases...');
    
    // Sort purchases by ID to ensure proper order
    purchases.sort((a, b) => (a.id ?? '0').compareTo(b.id ?? '0'));
    
    for (var purchase in purchases) {
      if (purchase.products != null) {
        print('📦 Processing purchase: ${purchase.invoiceNo} (ID: ${purchase.id})');
        List<Map<String, dynamic>> newSkuItems = [];
        
        for (var prod in purchase.products!) {
          int qty = prod.qty ?? 0;
          print('  📋 Product: ${prod.productName}, Quantity: $qty');
          
          for (int i = 0; i < qty; i++) {
            String sku = "SK${currentSkuNumber.toString().padLeft(8, '0')}";
            newSkuItems.add({
              "product": prod,
              "sku": sku,
              "index": i + 1,
            });
            print('    ✅ Generated SKU: $sku for item ${i + 1}');
            currentSkuNumber++;
          }
        }
        
        // Update purchase with new SKUs
        purchase.skuItems = newSkuItems;
        await updatePurchase(purchase);
        print('💾 Updated purchase ${purchase.invoiceNo} with ${newSkuItems.length} SKUs');
      }
    }
    
    print('🎯 Reset complete! Total SKUs generated: ${currentSkuNumber - 1}');
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    final data = purchase.toMap();
    data['products'] = jsonEncode(purchase.products?.map((p) => p.toMap()).toList() ?? []);
    await _db.insert('purchases', data);
  }

  Future<void> updatePurchase(PurchaseModel purchase) async {
    final data = purchase.toMap();
    data['products'] = jsonEncode(purchase.products?.map((p) => p.toMap()).toList() ?? []);
    await _db.update(
      'purchases',
      data,
      where: 'purchase_id = ?',
      whereArgs: [purchase.purchaseId],
    );
  }

  Future<List<PurchaseModel>> getAllPurchases() async {
    final result = await _db.query('purchases', orderBy: "id ASC"); // Changed to ASC to get oldest first
    return result.map((row) {
      final productsJson = row['products'] as String?;
      final productsList = productsJson != null
          ? (jsonDecode(productsJson) as List).map((p) => PurchaseProduct.fromMap(p)).toList()
          : [];
      return PurchaseModel.fromMap({...row, 'products': productsList});
    }).toList();
  }

  Future<List<PurchaseModel>> getAllPurchasesForUI() async {
    final result = await _db.query('purchases', orderBy: "id DESC"); // DESC for UI (newest first)
    return result.map((row) {
      final productsJson = row['products'] as String?;
      final productsList = productsJson != null
          ? (jsonDecode(productsJson) as List).map((p) => PurchaseProduct.fromMap(p)).toList()
          : [];
      return PurchaseModel.fromMap({...row, 'products': productsList});
    }).toList();
  }
}



