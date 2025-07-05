import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String address;
  final String? phoneNumber;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName = '',
    this.address = '',
    this.phoneNumber,
    this.role = 'user',
  });

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? 'No Name',
      address: data['address'] ?? 'No Address',
      phoneNumber: data['phoneNumber'],
      role: data['role'] ?? 'user',
    );
  }
}
