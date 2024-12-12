import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_edit_account.dart';
import 'employer_update_password_screen.dart';
import 'employerLogin.dart';



class EmployeeMenuDrawer extends StatelessWidget {
  final User user;

  EmployeeMenuDrawer({required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Employer').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
          String email = userData['email'] ?? 'N/A';
          String photoUrl = userData['photoUrl'] ?? '';

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(fullName),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                ),
                decoration: BoxDecoration(
                  color: Colors.red[300], // Change the header background color to red
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Account'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmployerEditAccountScreen(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lock),
                title: Text('Update Password'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmployerUpdatePasswordScreen(user: user),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmployerLoginPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
