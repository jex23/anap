import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom Imports
import 'employee_menu_drawer.dart';
import 'Employercreate_post.dart';
import 'application_detail.dart';
import 'Employer_messages.dart';
import 'employerHomepage.dart';
import 'job_applicants.dart';
import 'employer_comments_screen.dart';
import 'employer_post_service.dart'; // Import the new service

class EmployerCommunity extends StatelessWidget {
  final User? user;
  final EmployerPostService postService = EmployerPostService(); // Instantiate the service

  EmployerCommunity({this.user});

  // Fetch user data from Firestore
  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Employer')
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
            String currentFullName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            String currentPhotoUrl =
                userData['photoUrl'] ?? 'https://via.placeholder.com/150';

            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(currentPhotoUrl),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Hello, $currentFullName',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            );
          },
        ),
      ),
      drawer: user != null ? EmployeeMenuDrawer(user: user!) : null,
      body: Column(
        children: [
          // Post Feed Section
          Expanded(
            child: postService.buildPostList(context, user), // Use the new method
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
                builder: (context) => CreatePostScreen(user: user!)),
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
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => EmployerHomepage(user: user!)));
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => JobApplicants(user: user!)));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => EmployerMessages(user: user!)));
          } else if (index == 3) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => EmployerCommunity(user: user!)));
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search),
            label: 'Applicants',
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
