import 'package:flutter/material.dart';

class ProductItem extends StatelessWidget {
  final String ImageProduct;
  final String TitleProduct;
  final String CategoryProduct;
  final String PriceProduct;

  const ProductItem({
    super.key,
    required this.ImageProduct,
    required this.TitleProduct,
    required this.CategoryProduct,
    required this.PriceProduct,
  });

  @override
  Widget build(BuildContext context) {
    final TextColor = const Color(0xFF3D5154);
    final ColorItem = const Color(0xFF485F62);

    return Container(
      width: 190,
      // height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      padding: EdgeInsets.all(5),
      child: Container(
        // color: Colors.red,
        child: Container(
          child: Column(
            children: [
              Container(
                color: Color(0xFFF5F5F5),
                child: Image.asset(
                  ImageProduct,
                  // height: 150,
                  width: 190,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                // height: 200,
                alignment: Alignment.centerLeft,
                child: Text(
                  // TitleProduct,
                  'Rp. 200.000',
                  style: TextStyle(
                      color: TextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              Container(
                // height: 200,
                alignment: Alignment.centerLeft,
                child: Text(
                  // TitleProduct,
                  'New Original Pants',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 92, 92, 92),
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  CategoryProduct,
                  style: TextStyle(color: Color(0xFFC8CECF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
