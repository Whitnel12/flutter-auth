import 'package:flutter/material.dart';
import 'package:learning_auth/screens/bag_screen.dart';

class HomeScreen extends StatelessWidget {
  final TextColor = const Color(0xFF3D5154);
  final ColorItem = const Color(0xFF485F62);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Text(
            "Firjestore.",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          actions: <Widget>[
            IconButton(onPressed: () {}, icon: Icon(Icons.email_outlined)),
            IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none))
          ],
        ),
        body: Container(
          color: Color(0xffFAFAFA),
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/shoes.jpg',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Categories",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            backgroundColor: ColorItem,
                            padding: EdgeInsets.symmetric(horizontal: 20)),
                        child: Text(
                          "Dress",
                          style: TextStyle(color: Colors.white),
                        )),
                    SizedBox(width: 10),
                    TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20)),
                        child: Text(
                          "Shoes",
                          style: TextStyle(color: Color(0xFF8B999B)),
                        )),
                    SizedBox(width: 10),
                    TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20)),
                        child: Text(
                          "Pants",
                          style: TextStyle(color: Color(0xFF8B999B)),
                        )),
                    SizedBox(width: 10),
                    TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20)),
                        child: Text(
                          "Jacket",
                          style: TextStyle(color: Color(0xFF8B999B)),
                        )),
                  ],
                ),
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 181,
                        child: ProductItem(
                          ImageProduct: 'assets/jacket.png',
                          TitleProduct: 'Pants',
                          CategoryProduct: 'Pants',
                          PriceProduct: '10',
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 181,
                        child: ProductItem(
                          ImageProduct: 'assets/jacket.png',
                          TitleProduct: 'Pants',
                          CategoryProduct: 'Pants',
                          PriceProduct: '10',
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 181,
                        child: ProductItem(
                          ImageProduct: 'assets/jacket.png',
                          TitleProduct: 'Pants',
                          CategoryProduct: 'Pants',
                          PriceProduct: '10',
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 181,
                        child: ProductItem(
                          ImageProduct: 'assets/jacket.png',
                          TitleProduct: 'Pants',
                          CategoryProduct: 'Pants',
                          PriceProduct: '10',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Popular Product",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ProductItem(
                            ImageProduct: 'assets/jacket.png',
                            TitleProduct: 'Pants',
                            CategoryProduct: 'Pants',
                            PriceProduct: '10',
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}

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
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          Container(
            color: Color(0xFFF5F5F5),
            child: Image.asset(
              ImageProduct,
              height: 150,
              width: 190,
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              TitleProduct,
              style: TextStyle(
                  color: TextColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              CategoryProduct,
              style: TextStyle(color: Color(0xFFC8CECF)),
            ),
          ),
          Container(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  PriceProduct,
                  style: TextStyle(
                      fontSize: 18,
                      color: TextColor,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.add),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: ColorItem),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
