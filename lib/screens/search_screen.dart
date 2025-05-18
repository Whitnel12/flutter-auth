import 'package:flutter/material.dart';
import 'package:learning_auth/widgets/product_card.dart';
import 'package:learning_auth/widgets/product_item.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          "Search",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
            iconSize: 30,
          )
        ],
      ),
      body: Container(
        alignment: Alignment.topLeft,
        width: double.infinity,
        color: Color(0xffFAFAFA),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Featured Brands",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                ),
                Text(
                  "View More",
                  style: TextStyle(fontSize: 17, color: Color(0xFF0B6623)),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: GridView.count(
                primary: false,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                children: <Widget>[
                  // ProductItem
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                  ProductItem(
                      ImageProduct: 'assets/jacket.png',
                      TitleProduct: 'jacket',
                      CategoryProduct: 'jacket',
                      PriceProduct: '200.000'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
