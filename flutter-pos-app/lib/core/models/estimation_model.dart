class EstimationModel {
  final int? id;
  final String estimationNumber;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double grandTotal;
  final String status; // 'pending', 'converted', 'cancelled'
  final String createdAt;
  final int? userId;
  List<EstimationItemModel> items;

  EstimationModel({
    this.id,
    required this.estimationNumber,
    this.customerId,
    this.customerName,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.grandTotal,
    this.status = 'pending',
    required this.createdAt,
    this.userId,
    this.items = const [],
  });

  factory EstimationModel.fromMap(Map<String, dynamic> map) {
    return EstimationModel(
      id: map['id'],
      estimationNumber: map['estimation_number'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      status: map['status'],
      createdAt: map['created_at'],
      userId: map['user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'estimation_number': estimationNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'status': status,
      'created_at': createdAt,
      'user_id': userId,
    };
  }
}

class EstimationItemModel {
  final int? id;
  final int? estimationId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double taxPercent;
  final double total;

  EstimationItemModel({
    this.id,
    this.estimationId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.taxPercent,
    required this.total,
  });

  factory EstimationItemModel.fromMap(Map<String, dynamic> map) {
    return EstimationItemModel(
      id: map['id'],
      estimationId: map['estimation_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      taxPercent: (map['tax_percent'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (estimationId != null) 'estimation_id': estimationId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'tax_percent': taxPercent,
      'total': total,
    };
  }
}
