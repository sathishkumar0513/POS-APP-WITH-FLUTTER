import '../database/database_helper.dart';
import '../models/estimation_model.dart';
import '../models/sale_model.dart';
import 'sale_service.dart';

class EstimationService {
  Future<List<EstimationModel>> getAllEstimations() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('estimations', orderBy: 'created_at DESC');
    return result.map((m) => EstimationModel.fromMap(m)).toList();
  }

  Future<EstimationModel?> getEstimationById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('estimations', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final estimation = EstimationModel.fromMap(result.first);
    estimation.items = await getEstimationItems(id);
    return estimation;
  }

  Future<List<EstimationItemModel>> getEstimationItems(int estimationId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('estimation_items', where: 'estimation_id = ?', whereArgs: [estimationId]);
    return result.map((m) => EstimationItemModel.fromMap(m)).toList();
  }

  Future<int> insertEstimation(EstimationModel estimation) async {
    final db = await DatabaseHelper.instance.database;
    final eid = await db.insert('estimations', estimation.toMap());
    for (final item in estimation.items) {
      final itemMap = item.toMap();
      itemMap['estimation_id'] = eid;
      await db.insert('estimation_items', itemMap);
    }
    return eid;
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('estimations', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> convertToSale(EstimationModel estimation, String paymentMethod, double amountPaid) async {
    final saleService = SaleService();
    final saleItems = estimation.items.map((ei) => SaleItemModel(
      productId: ei.productId,
      productName: ei.productName,
      price: ei.price,
      quantity: ei.quantity,
      taxPercent: ei.taxPercent,
      total: ei.total,
    )).toList();

    final sale = SaleModel(
      invoiceNumber: saleService.generateInvoiceNumber(),
      customerId: estimation.customerId,
      customerName: estimation.customerName,
      subtotal: estimation.subtotal,
      taxAmount: estimation.taxAmount,
      discountAmount: estimation.discountAmount,
      grandTotal: estimation.grandTotal,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeAmount: amountPaid - estimation.grandTotal,
      createdAt: DateTime.now().toIso8601String(),
      userId: estimation.userId,
      items: saleItems,
    );

    final saleId = await saleService.insertSale(sale);
    await updateStatus(estimation.id!, 'converted');
    return saleId;
  }

  Future<int> deleteEstimation(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('estimation_items', where: 'estimation_id = ?', whereArgs: [id]);
    return await db.delete('estimations', where: 'id = ?', whereArgs: [id]);
  }

  String generateEstimationNumber() {
    final now = DateTime.now();
    return 'EST-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }
}
