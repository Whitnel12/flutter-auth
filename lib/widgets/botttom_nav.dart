import 'package:flutter/material.dart';
import 'package:learning_auth/screens/bag_screen.dart';
import 'package:learning_auth/screens/home_screen.dart';
import 'package:learning_auth/screens/profile_screen.dart';
import 'package:learning_auth/screens/search_screen.dart'; // Pastikan ini ada

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  List<int> _history = [0]; // <--- simpan jejak tab

  final List<Widget> _pages = [
    HomeScreen(),
    SearchScreen(),
    BagPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _history.add(index); // Simpan history tiap kali tab berpindah
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_history.length > 1) {
      _history.removeLast(); // Hapus tab sekarang
      setState(() {
        _selectedIndex = _history.last; // Balik ke tab sebelumnya
      });
      return false; // Jangan keluar app
    }
    return true; // Keluar app kalau udah di tab pertama
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 248, 247, 247),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFF0B6623),
          unselectedItemColor: Color(0xFF8B999B),
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Bag',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
// class BottomNav extends StatefulWidget {
//   @override
//   BottomNavState createState() => BottomNavState();
// }

// class BottomNavState extends State<BottomNav> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [
//     HomeScreen(),
//     SearchScreen(),
//     BagPage(),
//     ProfileScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color.fromARGB(255, 248, 247, 247),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xFF0B6623),
//         unselectedItemColor: Color(0xFF8B999B),
//         onTap: _onItemTapped,
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.search),
//             label: 'Search',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_bag),
//             label: 'Bag',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }
