import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom Imports
import 'menu_drawer.dart';
import 'userHomepage.dart';
import 'user_applications_status.dart';
import 'messages.dart';
import 'user_create_post.dart'; // Import for creating a post
import 'user_post_service.dart'; // Import for managing posts

class UserCommunityPage extends StatelessWidget {
  final User? user;
  final UserPostService postService = UserPostService(); // Instantiate the service

  UserCommunityPage({this.user});

  // Fetch user data from Firestore
  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Applicants')
        .doc(user!.uid)
        .get();
    return userDoc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        elevation: 0,
        title: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Error loading user data');
            }

            var userData = snapshot.data!;
            String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            String photoUrl = userData['photoUrl'] ?? 'https://via.placeholder.com/150';

            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Hello, $fullName',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            );
          },
        ),
      ),
      drawer: user != null ? MenuDrawer(user: user!) : null,
      body: Column(
        children: [
          // Post Feed Section
          Expanded(
            child: postService.buildPostList(context, user), // Use the service method
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[300],
        onPressed: () {
          // Navigate to Create Post screen
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UserCreatePostScreen(user: user!)),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.red[600],
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(user: user!)));
          } else if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserApplicationsStatusPage(user: user!)));
          } else if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MessagesPage(user: user!)));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => UserCommunityPage(user: user!)));
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}
