import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_auth/models/product.dart';
import 'package:learning_auth/screens/product_detail.dart';
import 'package:learning_auth/widgets/product_item.dart';
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextColor = const Color(0xFF3D5154);
  final ColorItem = const Color(0xFF485F62);
  String selectedCategory = 'all';
  int myCurrentIndex = 0;
  List<Product>? _cachedProducts;
  List<Product>? _featuredProducts;
  bool _isLoading = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      // Ambil semua produk terlebih dahulu
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .limit(50) // Increased limit for better selection
          .get();

      if (mounted) {
        setState(() {
          _cachedProducts = snapshot.docs
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

          // Select featured products (products with discount or high price for premium feel)
          _featuredProducts = _cachedProducts!
              .where((product) =>
                  (product.discount != null && product.discount! > 0) ||
                  product.price >
                      200000) // Lowered threshold for premium products
              .take(8) // Increased from 5 to 8
              .toList();

          // If no featured products, take first 8 products
          if (_featuredProducts!.isEmpty) {
            _featuredProducts = _cachedProducts!.take(8).toList();
          }

          // If still empty, take all available products (max 8)
          if (_featuredProducts!.isEmpty && _cachedProducts!.isNotEmpty) {
            _featuredProducts = _cachedProducts!.take(8).toList();
          }

          // Debug print
          print('📊 Carousel Debug:');
          print('   - Total cached products: ${_cachedProducts!.length}');
          print(
              '   - Featured products selected: ${_featuredProducts!.length}');
          print(
              '   - Featured products: ${_featuredProducts!.map((p) => p.name).toList()}');

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    if (selectedCategory == 'all') {
      return products;
    }
    return products
        .where((product) =>
            product.category.toLowerCase() == selectedCategory.toLowerCase())
        .toList();
  }

  Widget buildCategoryButton(String category) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: TextButton(
        onPressed: () {
          setState(() {
            selectedCategory = category.toLowerCase();
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: selectedCategory == category.toLowerCase()
              ? const Color(0xFF295D49)
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(
              color: selectedCategory == category.toLowerCase()
                  ? const Color(0xFF295D49)
                  : const Color(0xFFE0E0E0),
            ),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: selectedCategory == category.toLowerCase()
                ? Colors.white
                : const Color(0xFF7F8C8D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    if (_isLoading || _featuredProducts == null || _featuredProducts!.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF295D49),
              const Color(0xFF0B6623),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag, size: 50, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'FirjeStore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          myCurrentIndex = index;
          setState(() {});
        },
        itemCount: _featuredProducts!.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts![index];
          print('🎠 Building carousel item $index: ${product.name}');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetail(product: product),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF295D49),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF295D49),
        ),
      );
    }

    if (_cachedProducts == null || _cachedProducts!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Color(0xFF7F8C8D),
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada produk yang tersedia',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _filterProducts(_cachedProducts!);

    if (filteredProducts.isEmpty) {
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
              'Tidak ada produk dalam kategori ini',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured Products (Horizontal Scroll)
        Container(
          height: 266,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filteredProducts.take(4).map((product) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 181,
                    height: 266,
                    child: GestureDetector(
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
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Produk Populer",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            color: Color(0xFF3D5154),
          ),
        ),
        const SizedBox(height: 20),
        // Grid View of Products dengan height yang dinamis
        LayoutBuilder(
          builder: (context, constraints) {
            final itemHeight = 266.0;
            final crossAxisCount = 2;
            final crossAxisSpacing = 10.0;
            final mainAxisSpacing = 10.0;

            // Hitung jumlah baris yang dibutuhkan
            final itemCount = filteredProducts.length;
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
                  final product = filteredProducts[index];
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
        ),
      ],
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
        title: const Text(
          "FirjeStore",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Color(0xFF295D49),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF7F8C8D),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel
            _buildCarousel(),
            const SizedBox(height: 10),
            // Carousel Indicator
            if (_featuredProducts != null && _featuredProducts!.isNotEmpty) ...[
              Center(
                child: AnimatedSmoothIndicator(
                  activeIndex: myCurrentIndex,
                  count: _featuredProducts!.length,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 5,
                    dotColor: Colors.grey.shade300,
                    activeDotColor: const Color(0xFF295D49),
                    paintStyle: PaintingStyle.fill,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 30),
            const Text(
              "Kategori",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
                color: Color(0xFF3D5154),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildCategoryButton('All'),
                  buildCategoryButton('Pakaian'),
                  buildCategoryButton('Aksesoris'),
                  buildCategoryButton('Sepatu'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildProductList(),
          ],
        ),
      ),
    );
  }
}
