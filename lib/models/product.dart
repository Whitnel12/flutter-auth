import 'package:flutter/material.dart';

class Product {
  final String? id;
  final String name;
  final double price;
  final int stock;
  final String description;
  final String category;
  final String imageUrl;
  final int? discount;
  final Map<String, dynamic>? variants;
  final List<String>? availableSizes;
  final String? sizeType;
  final bool? isAvailable;
  final String status;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.discount,
    this.variants,
    this.availableSizes,
    this.sizeType,
    this.isAvailable,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'discount': discount,
      'variants': variants,
      'availableSizes': availableSizes,
      'sizeType': sizeType,
      'isAvailable': isAvailable,
      'status': status,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      discount: map['discount'],
      variants: map['variants'] != null
          ? Map<String, dynamic>.from(map['variants'])
          : null,
      availableSizes: map['availableSizes'] != null
          ? List<String>.from(map['availableSizes'])
          : null,
      sizeType: map['sizeType'],
      isAvailable: map['isAvailable'] ?? true,
      status: map['status'] ?? 'available',
    );
  }

  List<String> getSizesForCategory() {
    if (availableSizes != null && availableSizes!.isNotEmpty) {
      return availableSizes!;
    }

    switch (category.toLowerCase()) {
      case 'pakaian':
        return ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
      case 'sepatu':
        return ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45'];
      case 'aksesoris':
        return ['ONE SIZE', 'S', 'M', 'L'];
      default:
        return ['ONE SIZE'];
    }
  }

  String getSizeLabel() {
    switch (category.toLowerCase()) {
      case 'pakaian':
        return 'Ukuran Pakaian';
      case 'sepatu':
        return 'Ukuran Sepatu';
      case 'aksesoris':
        return 'Ukuran Aksesoris';
      default:
        return 'Ukuran';
    }
  }

  String getSizeGuide() {
    switch (category.toLowerCase()) {
      case 'pakaian':
        return 'Panduan Ukuran Pakaian';
      case 'sepatu':
        return 'Panduan Ukuran Sepatu';
      case 'aksesoris':
        return 'Panduan Ukuran Aksesoris';
      default:
        return 'Panduan Ukuran';
    }
  }

  bool get canBePurchased {
    if (isAvailable == null) {
      return stock > 0;
    }
    return isAvailable! &&
        stock > 0 &&
        (status == 'available' || status.isEmpty);
  }

  String get availabilityStatus {
    if (isAvailable == null) {
      if (stock <= 0) {
        return 'Stok Habis';
      }
      if (stock <= 5) {
        return 'Stok Terbatas';
      }
      return 'Tersedia';
    }

    if (!isAvailable! || status != 'available') {
      return 'Tidak Tersedia';
    }
    if (stock <= 0) {
      return 'Stok Habis';
    }
    if (stock <= 5) {
      return 'Stok Terbatas';
    }
    return 'Tersedia';
  }

  Color get availabilityColor {
    if (isAvailable == null) {
      if (stock <= 0) {
        return Colors.red;
      }
      if (stock <= 5) {
        return Colors.orange;
      }
      return const Color(0xFF0B6623);
    }

    if (!isAvailable! || status != 'available') {
      return Colors.grey;
    }
    if (stock <= 0) {
      return Colors.red;
    }
    if (stock <= 5) {
      return Colors.orange;
    }
    return const Color(0xFF0B6623);
  }
}
