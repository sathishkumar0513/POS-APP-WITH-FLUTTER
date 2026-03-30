class StoreModel {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String? gstNumber;
  final String? logoPath;

  StoreModel({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.gstNumber,
    this.logoPath,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      gstNumber: map['gst_number'],
      logoPath: map['logo_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'gst_number': gstNumber,
      'logo_path': logoPath,
    };
  }
}
