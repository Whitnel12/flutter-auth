import 'package:flutter/material.dart';

class ProductItem extends StatelessWidget {
  final String ImageProduct;
  final String TitleProduct;
  final String CategoryProduct;
  final String PriceProduct;
  final int stock;

  const ProductItem({
    super.key,
    required this.ImageProduct,
    required this.TitleProduct,
    required this.CategoryProduct,
    required this.PriceProduct,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final TextColor = const Color(0xFF3D5154);
    final ColorItem = const Color(0xFF485F62);

    return Container(
      width: 181,
      constraints: BoxConstraints(
        minHeight: 266, // Minimum height to ensure enough space
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image with Stock Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: const Color(0xFFF5F5F5),
                  child: Image.network(
                    ImageProduct,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    cacheHeight: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
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
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // "Stok Habis" Overlay
              if (stock <= 0)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Text(
                      'STOK HABIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price
                  Text(
                    PriceProduct,
                    style: TextStyle(
                      color: TextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Title
                  Expanded(
                    child: Text(
                      TitleProduct,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 92, 92, 92),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Category
                  Text(
                    CategoryProduct,
                    style: TextStyle(
                      color: Color(0xFFC8CECF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
