
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../Model/UserModel.dart';

class UserRepository {
  late Database _db;

  Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _db = await databaseFactory.openDatabase('app_data.db');

    await _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT,
        address TEXT,
        email TEXT,
        number TEXT,
        password TEXT
      );
    ''');
  }

  Future<void> registerUser(UserModel user) async {
    await _db.insert('users', user.toJson());
  }
}