import '../database/database_helper.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<ProductModel>> getAllProducts() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<ProductModel?> getByBarcode(String barcode) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (result.isEmpty) return null;
    return ProductModel.fromMap(result.first);
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> decreaseStock(int productId, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
      [quantity, productId],
    );
  }

  Future<List<String>> getCategories() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM products WHERE category IS NOT NULL ORDER BY category ASC');
    return result.map((m) => m['category'] as String).toList();
  }
}
