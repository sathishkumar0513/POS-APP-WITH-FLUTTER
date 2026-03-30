class ProductModel {
  final int? id;
  final String name;
  final String? imagePath;
  final String? barcode;
  final String? category;
  final double costPrice;
  final double sellingPrice;
  final double taxPercent;
  final int stockQuantity;

  ProductModel({
    this.id,
    required this.name,
    this.imagePath,
    this.barcode,
    this.category,
    required this.costPrice,
    required this.sellingPrice,
    this.taxPercent = 0.0,
    this.stockQuantity = 0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      imagePath: map['image_path'],
      barcode: map['barcode'],
      category: map['category'],
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      taxPercent: (map['tax_percent'] as num).toDouble(),
      stockQuantity: map['stock_quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_path': imagePath,
      'barcode': barcode,
      'category': category,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'tax_percent': taxPercent,
      'stock_quantity': stockQuantity,
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? imagePath,
    String? barcode,
    String? category,
    double? costPrice,
    double? sellingPrice,
    double? taxPercent,
    int? stockQuantity,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}
