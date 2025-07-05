import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  final String? name;
  final String? category;
  final double? price;
  final int? stock;
  final String? imageUrl;
  final String? description;
  final int? discount;
  final List<String>? availableSizes;
  final String? sizeType;

  const ProductFormScreen({
    super.key,
    this.productId,
    this.name,
    this.category,
    this.price,
    this.stock,
    this.imageUrl,
    this.description,
    this.discount,
    this.availableSizes,
    this.sizeType,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  String? _imageUrl;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  bool _isLoading = false;
  bool _isAvailable = true;
  String _status = 'available';

  // Size management
  List<String> _selectedSizes = [];
  List<String> _availableSizes = [];

  final List<String> _categories = [
    'Pakaian',
    'Aksesoris',
    'Sepatu',
  ];

  // Default sizes per category
  final Map<String, List<String>> _categorySizes = {
    'Pakaian': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    'Aksesoris': ['ONE SIZE', 'S', 'M', 'L'],
    'Sepatu': ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45'],
  };

  @override
  void initState() {
    super.initState();
    // Initialize form with existing data if editing
    if (widget.productId != null) {
      _nameController.text = widget.name ?? '';
      _priceController.text = widget.price?.toString() ?? '';
      _stockController.text = widget.stock?.toString() ?? '';
      _descriptionController.text = widget.description ?? '';
      _selectedCategory = widget.category;
      _imageUrl = widget.imageUrl;
      if (widget.discount != null) {
        _discountController.text = widget.discount.toString();
      }
      if (widget.availableSizes != null) {
        _selectedSizes = List.from(widget.availableSizes!);
      }
    }

    // Set default sizes based on category
    if (_selectedCategory != null) {
      _availableSizes = _categorySizes[_selectedCategory!] ?? [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      // Hanya clear selected sizes jika bukan edit mode atau kategori berubah
      if (widget.productId == null || widget.category != category) {
        _selectedSizes.clear();
      }
      if (category != null) {
        _availableSizes = _categorySizes[category] ?? [];
      } else {
        _availableSizes = [];
      }
    });
  }

  void _toggleSize(String size) {
    setState(() {
      if (_selectedSizes.contains(size)) {
        _selectedSizes.remove(size);
      } else {
        _selectedSizes.add(size);
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih minimal satu ukuran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'description': _descriptionController.text,
        'category': _selectedCategory!,
        'imageUrl': _imageUrl!,
        'discount': _discountController.text.isNotEmpty
            ? int.parse(_discountController.text)
            : null,
        'availableSizes': _selectedSizes,
        'sizeType': _selectedCategory!.toLowerCase(),
        'isAvailable': _isAvailable,
        'status': _status,
      };

      if (widget.productId != null) {
        // Update existing product
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(productData);
      } else {
        // Add new product
        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil disimpan'),
            backgroundColor: Color(0xFF0B6623),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFE74C3C),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 247, 247),
      appBar: AppBar(
        title: Text(
          widget.productId != null ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF295D49),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image URL Input
              Container(
                width: double.infinity,
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
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'URL Gambar Produk',
                    labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  initialValue: _imageUrl,
                  onChanged: (value) {
                    setState(() {
                      _imageUrl = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'URL gambar tidak boleh kosong';
                    }
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasAbsolutePath) {
                      return 'URL gambar tidak valid';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'URL harus dimulai dengan http:// atau https://';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Image Preview
              Center(
                child: Container(
                  width: 200,
                  height: 200,
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
                  child: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            cacheHeight: 300,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error_outline,
                                    size: 48, color: Color(0xFFE74C3C)),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF295D49),
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image,
                              size: 48, color: Color(0xFF7F8C8D)),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Product Name Input
              Container(
                width: double.infinity,
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
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk',
                    labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    if (value.length < 3) {
                      return 'Nama produk minimal 3 karakter';
                    }
                    if (value.length > 100) {
                      return 'Nama produk maksimal 100 karakter';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Container(
                width: double.infinity,
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
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: _onCategoryChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kategori tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

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
                    Text(
                      _selectedCategory != null
                          ? 'Ukuran ${_selectedCategory}'
                          : 'Pilih Kategori Terlebih Dahulu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D5154),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedCategory != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSizes.map((String size) {
                          final isSelected = _selectedSizes.contains(size);
                          return GestureDetector(
                            onTap: () => _toggleSize(size),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF295D49)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF295D49)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedSizes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ukuran yang dipilih: ${_selectedSizes.join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0B6623),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Silakan pilih kategori terlebih dahulu untuk melihat ukuran yang tersedia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price and Stock Row
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga',
                          labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harga harus berupa angka';
                          }
                          final price = double.parse(value);
                          if (price <= 0) {
                            return 'Harga harus lebih dari 0';
                          }
                          if (price > 999999999) {
                            return 'Harga terlalu besar (maksimal 999,999,999)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
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
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Stok',
                          labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                          helperText: 'Jumlah unit yang tersedia',
                          helperStyle: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Stok tidak boleh kosong';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Stok harus berupa angka';
                          }
                          final stock = int.parse(value);
                          if (stock < 0) {
                            return 'Stok tidak boleh negatif';
                          }
                          if (stock > 999999) {
                            return 'Stok terlalu besar (maksimal 999,999)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description Input
              Container(
                width: double.infinity,
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
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Produk',
                    labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    if (value.length < 10) {
                      return 'Deskripsi minimal 10 karakter';
                    }
                    if (value.length > 1000) {
                      return 'Deskripsi maksimal 1000 karakter';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Discount Input
              Container(
                width: double.infinity,
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
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Diskon (%) - Opsional',
                    labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return 'Diskon harus berupa angka';
                      }
                      final discount = int.parse(value);
                      if (discount < 0) {
                        return 'Diskon tidak boleh negatif';
                      }
                      if (discount > 100) {
                        return 'Diskon tidak boleh lebih dari 100%';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Availability Settings
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
                      'Pengaturan Ketersediaan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D5154),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Is Available Toggle
                    Row(
                      children: [
                        Switch(
                          value: _isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                              if (!value) {
                                _status = 'unavailable';
                              } else {
                                _status = 'available';
                              }
                            });
                          },
                          activeColor: const Color(0xFF0B6623),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAvailable
                                    ? 'Produk Tersedia'
                                    : 'Produk Tidak Tersedia',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isAvailable
                                      ? const Color(0xFF0B6623)
                                      : Colors.red,
                                ),
                              ),
                              Text(
                                _isAvailable
                                    ? 'Produk akan ditampilkan di katalog dan dapat dibeli'
                                    : 'Produk tidak akan ditampilkan di katalog',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Status Selection
                    if (_isAvailable) ...[
                      const Text(
                        'Status Produk:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D5154),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'available',
                            child: Text('Tersedia'),
                          ),
                          DropdownMenuItem(
                            value: 'out_of_stock',
                            child: Text('Stok Habis'),
                          ),
                          DropdownMenuItem(
                            value: 'discontinued',
                            child: Text('Tidak Diproduksi'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value ?? 'available';
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF295D49),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Simpan Produk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
