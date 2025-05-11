import 'package:flutter/material.dart';

class BagPage extends StatefulWidget {
  const BagPage({super.key});

  @override
  State<BagPage> createState() => _BagPageState();
}

class _BagPageState extends State<BagPage> {
  bool isChecked = false;
  final ItemColor = Color(0xFF0B6623);
  final TextColor = const Color(0xFF3D5154);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          "Bag",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
      ),

      // body: Text("data"),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 95,
              // color: Colors.amber,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CheckboxTheme(
                      data: CheckboxThemeData(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      child: Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: ItemColor,
                          onChanged: (bool? value) {
                            setState(() {
                              isChecked = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Image.asset(
                    "assets/jacket.png",
                    height: 100,
                  ),
                  Expanded(
                    child: Container(
                      // color: Colors.red,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Jacket",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Size m",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            // color: Colors.amber,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "200.000",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            onPressed: () {},
                                            child: Center(
                                                child: Text(
                                              "-",
                                              style: TextStyle(fontSize: 16),
                                            ))),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "100",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ItemColor,
                                            padding: EdgeInsets
                                                .zero, // Hapus padding default
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          onPressed: () {},
                                          child: Center(
                                            // Pastikan isi di-center
                                            child: Text(
                                              "+",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors
                                                      .white), // Atur ukuran teks
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),

            // Text("data"),
            // BottomNavigationBar: ,
          ],
        ),
      ),

      bottomNavigationBar: Container(
          color: Colors.white,
          padding: EdgeInsets.all(20),
          // color: Colors.red,
          height: 160,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CheckboxTheme(
                          data: CheckboxThemeData(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          child: Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: ItemColor,
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Choose all",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  Text(
                    "Rp. 200.000",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Expanded(
                child: Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        "Checkout",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Color(0xFF0B6623),
                          foregroundColor: Colors.white),
                    )),
              ),
            ],
          )),
    );
  }
}
