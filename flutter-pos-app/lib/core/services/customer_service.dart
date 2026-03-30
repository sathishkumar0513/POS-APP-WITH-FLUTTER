import '../database/database_helper.dart';
import '../models/customer_model.dart';

class CustomerService {
  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((m) => CustomerModel.fromMap(m)).toList();
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((m) => CustomerModel.fromMap(m)).toList();
  }

  Future<int> insertCustomer(CustomerModel customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
