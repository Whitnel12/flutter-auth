import 'package:flutter/material.dart';
import 'package:learning_auth/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetail extends StatefulWidget {
  final Product product;

  const ProductDetail({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  String? selectedSize;
  bool _isLoading = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  void _selectSize(String size) {
    setState(() {
      selectedSize = size;
    });
  }

  Future<void> _addToCart() async {
    if (selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih ukuran terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Periksa ketersediaan produk
    if (!widget.product.canBePurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maaf, produk ${widget.product.availabilityStatus.toLowerCase()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Periksa stok produk
    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, stok produk habis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if product already exists in cart
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(currentUser?.uid)
          .collection('items')
          .where('productId', isEqualTo: widget.product.id);

      final existingItems = await cartRef.get();

      if (existingItems.docs.isNotEmpty) {
        // Update quantity if product exists
        final existingItem = existingItems.docs.first;
        final currentQuantity = existingItem.data()['quantity'] ?? 1;
        final newQuantity = currentQuantity + 1;

        // Periksa apakah quantity baru tidak melebihi stok
        if (newQuantity > widget.product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Stok tidak mencukupi. Stok tersedia: ${widget.product.stock}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await existingItem.reference.update({
          'quantity': newQuantity,
          'stock': widget.product.stock, // Update stok terbaru
        });
      } else {
        // Add new item to cart
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(currentUser?.uid)
            .collection('items')
            .add({
          'productId': widget.product.id,
          'name': widget.product.name,
          'price': widget.product.price,
          'imageUrl': widget.product.imageUrl,
          'category': widget.product.category,
          'size': selectedSize,
          'quantity': 1,
          'stock': widget.product.stock,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan ke keranjang'),
            backgroundColor: Color(0xFF0B6623),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// Tambah
  double _getDiscountedPrice() {
    if (widget.product.discount != null && widget.product.discount! > 0) {
      return widget.product.price * (1 - widget.product.discount! / 100);
    }
    return widget.product.price;
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = _getDiscountedPrice();
    final hasDiscount =
        widget.product.discount != null && widget.product.discount! > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D5154)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.favorite_border,
              color: Color(0xFF3D5154),
            ),
          )
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  cacheHeight: 400,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Center(
                        child: Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF295D49),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D5154),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              'Rp${widget.product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7F8C8D),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            'Rp${discountedPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount
                                  ? Colors.red
                                  : const Color(0xFF0B6623),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stock Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.product.stock > 0
                          ? const Color(0xFF0B6623).withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.product.stock > 0
                            ? const Color(0xFF0B6623).withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.product.stock > 0
                          ? 'Stok: ${widget.product.stock}'
                          : 'Stok Habis',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.product.stock > 0
                            ? const Color(0xFF0B6623)
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Category and Discount Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B6623).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: const Color(0xFF0B6623),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.category,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B6623),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.product.discount}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deskripsi Produk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D5154),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stock Information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.product.availabilityColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: widget.product.availabilityColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status Ketersediaan',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                widget.product.availabilityStatus,
                                style: TextStyle(
                                  color: widget.product.availabilityColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.product.stock > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Stok: ${widget.product.stock} unit',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Size Selection
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.product.getSizeLabel(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D5154),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _showSizeGuide();
                              },
                              child: Text(
                                widget.product.getSizeGuide(),
                                style: const TextStyle(
                                  color: Color(0xFF0B6623),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              widget.product.getSizesForCategory().map((size) {
                            return _buildSizeButton(size);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: Container(
          // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          // height: 200,
          child: ElevatedButton.icon(
            onPressed:
                widget.product.stock > 0 && !_isLoading ? _addToCart : null,
            icon: Icon(
              widget.product.stock > 0
                  ? Icons.add_shopping_cart
                  : Icons.remove_shopping_cart_outlined,
              color: Colors.white,
            ),
            label: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(
                    widget.product.stock > 0
                        ? 'Tambah ke Keranjang'
                        : 'Stok Habis',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              // height: 80,
              backgroundColor: widget.product.stock > 0
                  ? const Color(0xFF295D49)
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeButton(String size) {
    final bool isSelected = selectedSize == size;

    return GestureDetector(
      onTap: () => _selectSize(size),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? const Color(0xFF295D49) : const Color(0xFFE0E0E0),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(28),
          color: isSelected
              ? const Color(0xFF295D49).withOpacity(0.1)
              : Colors.white,
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF295D49)
                  : const Color(0xFF3D5154),
            ),
          ),
        ),
      ),
    );
  }

  void _showSizeGuide() {
    String title = widget.product.getSizeGuide();
    String content = '';

    switch (widget.product.category.toLowerCase()) {
      case 'pakaian':
        content = '''
Panduan Ukuran Pakaian:

XS - Extra Small: Lingkar dada 90-95 cm
S - Small: Lingkar dada 95-100 cm  
M - Medium: Lingkar dada 100-105 cm
L - Large: Lingkar dada 105-110 cm
XL - Extra Large: Lingkar dada 110-115 cm
XXL - Extra Extra Large: Lingkar dada 115-120 cm

Cara mengukur:
1. Ukur lingkar dada di bagian terlebar
2. Pastikan meteran tidak terlalu ketat atau longgar
3. Pilih ukuran yang paling sesuai
        ''';
        break;
      case 'sepatu':
        content = '''
Panduan Ukuran Sepatu:

36 - Panjang kaki 23 cm
37 - Panjang kaki 23.5 cm
38 - Panjang kaki 24 cm
39 - Panjang kaki 24.5 cm
40 - Panjang kaki 25 cm
41 - Panjang kaki 25.5 cm
42 - Panjang kaki 26 cm
43 - Panjang kaki 26.5 cm
44 - Panjang kaki 27 cm
45 - Panjang kaki 27.5 cm

Cara mengukur:
1. Letakkan kaki di atas kertas
2. Tandai ujung jari terpanjang dan tumit
3. Ukur jarak antara kedua tanda
4. Pilih ukuran yang paling sesuai
        ''';
        break;
      case 'aksesoris':
        content = '''
Panduan Ukuran Aksesoris:

ONE SIZE - Cocok untuk semua ukuran
S - Small: Lingkar kepala 54-56 cm
M - Medium: Lingkar kepala 56-58 cm
L - Large: Lingkar kepala 58-60 cm

Cara mengukur:
1. Ukur lingkar kepala di atas telinga
2. Pastikan meteran tidak terlalu ketat
3. Pilih ukuran yang paling sesuai
        ''';
        break;
      default:
        content = 'Panduan ukuran tidak tersedia untuk kategori ini.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
