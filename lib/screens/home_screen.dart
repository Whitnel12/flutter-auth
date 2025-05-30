import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:learning_auth/screens/bag_screen.dart';
import 'package:learning_auth/screens/product_detail.dart';
import 'package:learning_auth/widgets/product_item.dart';
import 'package:carousel_slider/carousel_slider.dart';
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextColor = const Color(0xFF3D5154);

  final ColorItem = const Color(0xFF485F62);

  String Selected = 'dress';

  int myCurrentIndex = 0;

  // String isSelected = 'dress';

  final myItems = [
    Image.asset('assets/shoes.jpg'),
    Image.asset('assets/shoes.jpg'),
    Image.asset('assets/shoes.jpg'),
    Image.asset('assets/shoes.jpg'),
    Image.asset('assets/shoes.jpg'),
  ];

  Widget buildCategoryButton(String category) {
    return TextButton(
        onPressed: () {
          setState(() {
            Selected = category;
          });
          print(Selected);
        },
        style: TextButton.styleFrom(
            backgroundColor:
                Selected.toLowerCase().trim() == category.toLowerCase().trim()
                    ? ColorItem
                    : Colors.white,

            // backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20)),
        child: Text(
          category,
          style: TextStyle(
            color:
                Selected.toLowerCase().trim() == category.toLowerCase().trim()
                    ? Colors.white
                    : Color(0xFF8B999B),
          ),
        ));
  }

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
                CarouselSlider(
                  options: CarouselOptions(
                      autoPlay: true,
                      height: 200,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      enlargeCenterPage: true,
                      aspectRatio: 2.0,
                      autoPlayInterval: const Duration(seconds: 2),
                      onPageChanged: (index, reason) {
                        setState(() {
                          myCurrentIndex = index;
                        });
                      }),
                  items: myItems.map((item) {
                    return ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10), // 👈 Border radius di sini
                      child: item,
                    );
                  }).toList(),
                ),
                Center(
                  child: AnimatedSmoothIndicator(
                    activeIndex: myCurrentIndex,
                    count: myItems.length,
                    effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 5,
                        dotColor: Colors.grey.shade200,
                        activeDotColor: Colors.grey.shade900,
                        paintStyle: PaintingStyle.fill),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Categories",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                ),
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildCategoryButton('Dress'),
                      SizedBox(width: 10),
                      buildCategoryButton('Shoes'),
                      SizedBox(width: 10),
                      buildCategoryButton('Jacket'),
                      SizedBox(width: 10),
                      buildCategoryButton('pants'),
                      SizedBox(width: 10),
                      buildCategoryButton('bag'),
                      SizedBox(width: 10),
                    ],
                  ),
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
                GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    mainAxisExtent: 266,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProductDetail())),
                      child: ProductItem(
                        ImageProduct: 'assets/jacket.png',
                        TitleProduct: 'jacket',
                        CategoryProduct: 'jacket',
                        PriceProduct: '200.000',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ));
  }
}
