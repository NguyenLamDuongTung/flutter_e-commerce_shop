class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  AppUser copyWith({String? fullName, String? phone, String? address}) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }
}
