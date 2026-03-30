import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double discount;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  double get subtotal => product.sellingPrice * quantity;
  double get taxAmount => subtotal * (product.taxPercent / 100);
  double get total => subtotal + taxAmount - discount;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? discount,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}
