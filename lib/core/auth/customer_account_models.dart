import 'package:flutter/foundation.dart';

@immutable
class CustomerAccount {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String language;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? countryCode;

  const CustomerAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.language,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    this.gender,
    this.dateOfBirth,
    this.countryCode,
  });

  factory CustomerAccount.fromJson(Map<String, dynamic> json) {
    return CustomerAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      status: json['status']?.toString() ?? 'active',
      emailVerified: json['email_verified'] == true,
      phoneVerified: json['phone_verified'] == true,
      gender: json['gender']?.toString(),
      dateOfBirth: DateTime.tryParse(json['date_of_birth']?.toString() ?? ''),
      countryCode: json['country_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'language': language,
        'status': status,
        'email_verified': emailVerified,
        'phone_verified': phoneVerified,
        'gender': gender,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'country_code': countryCode,
      };

  CustomerAccount copyWith({
    String? name,
    String? email,
    String? phone,
    String? language,
    String? status,
    bool? emailVerified,
    bool? phoneVerified,
    String? gender,
    DateTime? dateOfBirth,
    String? countryCode,
  }) {
    return CustomerAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}

@immutable
class CustomerAuthResult {
  final CustomerAccount customer;
  final String token;

  const CustomerAuthResult({
    required this.customer,
    required this.token,
  });
}
