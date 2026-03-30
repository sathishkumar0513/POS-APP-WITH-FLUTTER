class SaleModel {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod; // 'cash', 'upi', 'card'
  final double amountPaid;
  final double changeAmount;
  final String createdAt;
  final int? userId;
  List<SaleItemModel> items;

  SaleModel({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeAmount,
    required this.createdAt,
    this.userId,
    this.items = const [],
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      paymentMethod: map['payment_method'],
      amountPaid: (map['amount_paid'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      createdAt: map['created_at'],
      userId: map['user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'created_at': createdAt,
      'user_id': userId,
    };
  }
}

class SaleItemModel {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double taxPercent;
  final double total;

  SaleItemModel({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.taxPercent,
    required this.total,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'],
      saleId: map['sale_id'],
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
      if (saleId != null) 'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'tax_percent': taxPercent,
      'total': total,
    };
  }
}
