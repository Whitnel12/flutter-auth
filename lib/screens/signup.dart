import 'package:flutter/material.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.only(top: 80, right: 30, left: 30, bottom: 30),
        child: Column(
          children: [
            Text(
              "Eccomerce",
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff22327B)),
            ),
            SizedBox(height: 60),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Create to your Account",
                // textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff636363),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: "Email"),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: "Password"),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: "Confirm Password"),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 60,
              child: TextButton(
                  style: TextButton.styleFrom(
                      backgroundColor: Color(0xff2E2C97),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: TextStyle(fontSize: 18)),
                  onPressed: () {},
                  child: Text("Sign")),
            ),
            SizedBox(height: 70),
            Container(
              // alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Have an account?'),
                  SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/");
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
