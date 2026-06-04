class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // CLIENT, ADMIN, VENDOR
  final String? phone;
  final String? company;
  final String? gstNumber;
  final String? postalCode;
  final String? address;
  final String? avatarUrl;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.company,
    this.gstNumber,
    this.postalCode,
    this.address,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      gstNumber: json['gstNumber'] as String?,
      postalCode: json['postalCode'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'company': company,
      'gstNumber': gstNumber,
      'postalCode': postalCode,
      'address': address,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? company,
    String? gstNumber,
    String? postalCode,
    String? address,
    String? avatarUrl,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      gstNumber: gstNumber ?? this.gstNumber,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
