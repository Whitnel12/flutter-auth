import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: Icon(Icons.email_outlined)),
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none))
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 236, 236, 236),
                    radius: 35,
                    backgroundImage: AssetImage("assets/jacket.png"),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Irwan Syahrir",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      Text("irwansyahrir@gmail.com"),
                    ],
                  )
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "General Setting",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(
                height: 25,
              ),
              ListTile(
                IconTile: Icons.person_outline,
                LabelTile: "My Account",
              ),
              SizedBox(
                height: 20,
              ),
              ListTile(
                IconTile: Icons.payment_outlined,
                LabelTile: "Payment Methods",
              ),
              SizedBox(
                height: 20,
              ),
              ListTile(
                IconTile: Icons.location_on_outlined,
                LabelTile: "My Address",
              ),
              SizedBox(
                height: 20,
              ),
              ListTile(
                IconTile: Icons.notifications_none,
                LabelTile: "Notifications",
              ),
              SizedBox(
                height: 25,
              ),
              Text(
                "Other",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(
                height: 25,
              ),
              ListTile(
                IconTile: Icons.contact_page_outlined,
                LabelTile: "Contact preferences",
              ),
              SizedBox(
                height: 20,
              ),
              ListTile(
                IconTile: Icons.description_outlined,
                LabelTile: "Terms and conditions",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListTile extends StatelessWidget {
  final IconData IconTile;
  final String LabelTile;

  const ListTile({
    super.key,
    required this.IconTile,
    required this.LabelTile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                // Icons.person_outline,
                IconTile,
                size: 30,
                color: const Color.fromARGB(255, 79, 79, 79),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                LabelTile,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          Icon(
            Icons.chevron_right,
            size: 30,
          ),
        ],
      ),
    );
  }
}
