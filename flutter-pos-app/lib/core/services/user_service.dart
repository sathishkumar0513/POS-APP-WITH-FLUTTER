import '../database/database_helper.dart';
import '../models/user_model.dart';

class UserService {
  Future<List<UserModel>> getAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('users', orderBy: 'name ASC');
    return result.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> insertUser(UserModel user) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> usernameExists(String username, {int? excludeId}) async {
    final db = await DatabaseHelper.instance.database;
    String where = 'username = ?';
    List<dynamic> args = [username];
    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }
    final result = await db.query('users', where: where, whereArgs: args);
    return result.isNotEmpty;
  }
}
