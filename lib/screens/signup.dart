// import 'package:flutter/material.dart';

// class SignUp extends StatelessWidget {
//   const SignUp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding:
//             const EdgeInsets.only(top: 80, right: 30, left: 30, bottom: 30),
//         child: Column(
//           children: [
//             Text(
//               "Eccomerce",
//               style: TextStyle(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xff22327B)),
//             ),
//             SizedBox(height: 60),
//             Container(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "Create to your Account",
//                 // textAlign: TextAlign.start,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xff636363),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               decoration: InputDecoration(
//                   border: OutlineInputBorder(), hintText: "Email"),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               decoration: InputDecoration(
//                   border: OutlineInputBorder(), hintText: "Password"),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               decoration: InputDecoration(
//                   border: OutlineInputBorder(), hintText: "Confirm Password"),
//             ),
//             SizedBox(height: 20),
//             Container(
//               width: double.infinity,
//               height: 60,
//               child: TextButton(
//                   style: TextButton.styleFrom(
//                       backgroundColor: Color(0xff2E2C97),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8)),
//                       textStyle: TextStyle(fontSize: 18)),
//                   onPressed: () {},
//                   child: Text("Sign")),
//             ),
//             SizedBox(height: 70),
//             Container(
//               // alignment: Alignment.center,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Have an account?'),
//                   SizedBox(
//                     width: 5,
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pushNamed(context, "/");
//                     },
//                     child: Text(
//                       "Sign In",
//                       style: TextStyle(color: Colors.blue[900]),
//                     ),
//                   )
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUp extends StatelessWidget {
  SignUp({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _registerUser(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password tidak cocok")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil")),
      );
      Navigator.pushNamed(context, "/");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal registrasi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.only(top: 80, right: 30, left: 30, bottom: 30),
        child: Column(
          children: [
            const Text(
              "Ecommerce",
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff22327B)),
            ),
            const SizedBox(height: 60),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Create your Account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff636363),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "Email"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "Password"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xff2E2C97),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () => _registerUser(context),
                child: const Text("Sign Up"),
              ),
            ),
            const SizedBox(height: 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Have an account?'),
                const SizedBox(width: 5),
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
            )
          ],
        ),
      ),
    );
  }
}
