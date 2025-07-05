import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

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
        const SnackBar(content: Text("Jangan ada yang kosong yaa :)")),
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
      // Buat akun Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data user ke Firestore dengan role pelanggan
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'role': 'pelanggan',
        'fullName': '',
        'phoneNumber': '',
        'addresses': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil!")),
      );
      Navigator.pushNamed(context, "/login");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal registrasi: $e")),
      );
    }
  }

  // void _registerUser(BuildContext context) async {
  //   final email = _emailController.text.trim();
  //   final password = _passwordController.text.trim();
  //   final confirmPassword = _confirmPasswordController.text.trim();

  //   if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Jangan ada yang kosong yaa :)")),
  //     );
  //     return;
  //   }

  //   if (password != confirmPassword) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Password tidak cocok")),
  //     );
  //     return;
  //   }

  //   try {
  //     await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Registrasi berhasil!")),
  //     );
  //     Navigator.pushNamed(context, "/login");
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Gagal registrasi: $e")),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF295D49);
    final grey = const Color(0xFF7F8C8D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 30, left: 30, bottom: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  60,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/logo.png',
                      height: 200,
                      width: 200,
                    ),
                  ),
                  // const SizedBox(height: 40),
                  const Text(
                    "Create your Account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Enter your Firjestore account details for profesional experience ",
                    style: TextStyle(
                      fontSize: 16,
                      color: grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      // filled: true,
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      // filled: true,
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      // filled: true,
                      labelText: "Confirm Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // TextField(
                  //   controller: _emailController,
                  //   style: TextStyle(color: Colors.white),
                  //   decoration: InputDecoration(
                  //     hintText: "Email",
                  //     hintStyle: TextStyle(color: Colors.white70),
                  //     filled: true,
                  //     fillColor: Colors.white.withOpacity(0.1),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: BorderSide.none,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),
                  // TextField(
                  //   controller: _passwordController,
                  //   obscureText: true,
                  //   style: TextStyle(color: Colors.white),
                  //   decoration: InputDecoration(
                  //     hintText: "Password",
                  //     hintStyle: TextStyle(color: Colors.white70),
                  //     filled: true,
                  //     fillColor: Colors.white.withOpacity(0.1),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: BorderSide.none,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),
                  // TextField(
                  //   controller: _confirmPasswordController,
                  //   obscureText: true,
                  //   style: TextStyle(color: Colors.white),
                  //   decoration: InputDecoration(
                  //     hintText: "Confirm Password",
                  //     hintStyle: TextStyle(color: Colors.white70),
                  //     filled: true,
                  //     fillColor: Colors.white.withOpacity(0.1),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: BorderSide.none,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _registerUser(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF295D49),
                        // foregroundColor: Color(0xFF295D49),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Have an account?",
                          // style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/login");
                          },
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                                color: green, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
