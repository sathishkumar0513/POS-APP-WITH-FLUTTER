import '../database/database_helper.dart';
import '../models/sale_model.dart';
import 'product_service.dart';

class SaleService {
  final ProductService _productService = ProductService();

  Future<List<SaleModel>> getAllSales() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('sales', orderBy: 'created_at DESC');
    return result.map((m) => SaleModel.fromMap(m)).toList();
  }

  Future<List<SaleModel>> getSalesForToday() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final result = await db.query(
      'sales',
      where: 'created_at LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );
    return result.map((m) => SaleModel.fromMap(m)).toList();
  }

  Future<List<SaleModel>> getSalesByDateRange(DateTime from, DateTime to) async {
    final db = await DatabaseHelper.instance.database;
    final fromStr = from.toIso8601String().substring(0, 10);
    final toStr = to.toIso8601String().substring(0, 10);
    final result = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: ['$fromStr 00:00:00', '$toStr 23:59:59'],
      orderBy: 'created_at DESC',
    );
    return result.map((m) => SaleModel.fromMap(m)).toList();
  }

  Future<SaleModel?> getSaleById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final sale = SaleModel.fromMap(result.first);
    sale.items = await getSaleItems(id);
    return sale;
  }

  Future<List<SaleItemModel>> getSaleItems(int saleId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    return result.map((m) => SaleItemModel.fromMap(m)).toList();
  }

  Future<int> insertSale(SaleModel sale) async {
    final db = await DatabaseHelper.instance.database;
    final saleId = await db.insert('sales', sale.toMap());
    for (final item in sale.items) {
      final itemMap = item.toMap();
      itemMap['sale_id'] = saleId;
      await db.insert('sale_items', itemMap);
      await _productService.decreaseStock(item.productId, item.quantity);
    }
    return saleId;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todaySales = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(grand_total) as total FROM sales WHERE created_at LIKE ?',
      ['$dateStr%'],
    );
    final totalSales = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(grand_total) as total FROM sales',
    );
    return {
      'today_count': todaySales.first['count'] ?? 0,
      'today_total': todaySales.first['total'] ?? 0.0,
      'total_count': totalSales.first['count'] ?? 0,
      'total_amount': totalSales.first['total'] ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT product_name, SUM(quantity) as total_qty, SUM(total) as total_amount
      FROM sale_items
      GROUP BY product_id, product_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);
    return result.cast<Map<String, dynamic>>();
  }

  String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }
}
