import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_auth/models/product.dart';
import 'package:learning_auth/widgets/product_item.dart';
import 'package:learning_auth/screens/product_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<Product> _searchResults = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'All',
    'Pakaian',
    'Aksesoris',
    'Sepatu',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil semua produk terlebih dahulu
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .limit(100) // Increased limit for better search
          .get();

      setState(() {
        _allProducts = snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .where((product) {
          // Filter hanya produk yang statusnya aktif
          final isActive =
              product.status == 'available' || product.status.isEmpty;

          // Untuk produk lama yang belum memiliki field isAvailable
          if (product.isAvailable == null) {
            return isActive;
          }

          return product.isAvailable! && isActive;
        }).toList();
        _filteredProducts = _allProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading products: $e');
    }
  }

  void _filterProducts() {
    setState(() {
      if (_selectedCategory == 'All') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) => product.category == _selectedCategory)
            .toList();
      }

      // Jika ada search query, filter berdasarkan search query juga
      if (_searchQuery.isNotEmpty) {
        _searchResults = _filteredProducts.where((product) {
          return product.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
        }).toList();
      } else {
        _searchResults = [];
      }
    });
  }

  Future<void> _performSearch(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Filter berdasarkan search query dan kategori yang dipilih
      final filteredResults = _filteredProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error searching products: $e');
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: () => _onCategoryChanged(category),
              style: TextButton.styleFrom(
                backgroundColor:
                    isSelected ? const Color(0xFF295D49) : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF295D49)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
              ),
              child: Text(
                category == 'All' ? 'Semua' : category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Color(0xFF7F8C8D),
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada produk ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemHeight = 266.0;
        final crossAxisCount = 2;
        final crossAxisSpacing = 10.0;
        final mainAxisSpacing = 10.0;

        // Hitung jumlah baris yang dibutuhkan
        final itemCount = products.length;
        final rowCount = (itemCount / crossAxisCount).ceil();
        final totalHeight =
            (rowCount * itemHeight) + ((rowCount - 1) * mainAxisSpacing);

        return Container(
          height: totalHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              mainAxisExtent: itemHeight,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetail(product: product),
                  ),
                ),
                child: ProductItem(
                  ImageProduct: product.imageUrl,
                  TitleProduct: product.name,
                  CategoryProduct: product.category,
                  PriceProduct: 'Rp${product.price.toStringAsFixed(0)}',
                  stock: product.stock,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '🔍 Cari produk...',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.search, color: Color(0xFF7F8C8D)),
              hintStyle: TextStyle(color: Color(0xFF7F8C8D)),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _performSearch(value);
            },
          ),
        ),
        actions: <Widget>[
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchResults = [];
                });
              },
              icon: const Icon(
                Icons.clear,
                color: Color(0xFF7F8C8D),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D5154),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoryFilter(),
              ],
            ),
          ),
          // Search Results
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF295D49),
                      ),
                    )
                  : _searchQuery.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategory == 'All'
                                  ? 'Semua Produk'
                                  : 'Produk Kategori $_selectedCategory',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D5154),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_filteredProducts.length} produk ditemukan',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildProductGrid(_filteredProducts),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil Pencarian "${_searchQuery}" (${_searchResults.length} produk)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3D5154),
                              ),
                            ),
                            if (_selectedCategory != 'All')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Kategori: $_selectedCategory',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            _buildProductGrid(_searchResults),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
