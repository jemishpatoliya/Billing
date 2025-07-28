
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
      password TEXT,
      role TEXT
    );
  ''');
  }

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

}