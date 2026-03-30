import '../database/database_helper.dart';
import '../models/store_model.dart';

class StoreService {
  Future<StoreModel?> getStore() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('stores', limit: 1);
    if (result.isEmpty) return null;
    return StoreModel.fromMap(result.first);
  }

  Future<int> saveStore(StoreModel store) async {
    final db = await DatabaseHelper.instance.database;
    if (store.id != null) {
      return await db.update('stores', store.toMap(), where: 'id = ?', whereArgs: [store.id]);
    } else {
      return await db.insert('stores', store.toMap());
    }
  }

  Future<bool> isConfigured() async {
    final store = await getStore();
    return store != null;
  }
}
