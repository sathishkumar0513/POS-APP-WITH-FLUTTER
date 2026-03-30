import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _keyUserId = 'logged_user_id';
  static const String _keyUserRole = 'logged_user_role';
  static const String _keyUserName = 'logged_user_name';

  Future<UserModel?> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, password],
    );
    if (result.isEmpty) return null;
    final user = UserModel.fromMap(result.first);
    await _saveSession(user);
    return user;
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, user.id!);
    await prefs.setString(_keyUserRole, user.role);
    await prefs.setString(_keyUserName, user.name);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    if (userId == null) return null;
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserName);
  }
}
