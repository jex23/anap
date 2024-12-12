import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_account.dart';
import 'update_password_screen.dart';
import 'userLogin.dart';
import 'upload_resume.dart';
import 'view_resume.dart';

class MenuDrawer extends StatelessWidget {
  final User user;

  MenuDrawer({required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Applicants').doc(user.uid).get(),
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
                      builder: (context) => EditAccountScreen(user: user),
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
                      builder: (context) => UpdatePasswordScreen(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('Upload Resume and Job Details'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UploadResumeScreen(userId: user.uid), // Pass userId
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('View Resume'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ViewResumeScreen(userId: user.uid),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  bool rememberMe = prefs.getBool('remember_me') ?? false;

                  // If "Remember Me" is not checked, clear saved credentials
                  if (!rememberMe) {
                    await prefs.remove('email');
                    await prefs.remove('password');
                    await prefs.remove('remember_me');
                  }

                  await FirebaseAuth.instance.signOut();

                  // Navigate to the Login page after logging out
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
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
