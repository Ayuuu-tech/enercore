class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // CLIENT, ADMIN, VENDOR
  final List<String> modules; // allowed modules; empty = all
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
    this.modules = const [],
    this.phone,
    this.company,
    this.gstNumber,
    this.postalCode,
    this.address,
    this.avatarUrl,
    this.createdAt,
  });

  /// Whether the user can access a given module key. Empty list = all allowed.
  bool canAccess(String module) => modules.isEmpty || modules.contains(module);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      modules: (json['modules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
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
      'modules': modules,
      'phone': phone,
      'company': company,
      'gstNumber': gstNumber,
      'postalCode': postalCode,
      'address': address,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
    };
  }
}
