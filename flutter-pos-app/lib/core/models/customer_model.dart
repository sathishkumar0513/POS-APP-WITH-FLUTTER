class CustomerModel {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}
