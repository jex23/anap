import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_drawer.dart';
import 'recommendation_widget.dart';
import 'graduate_jobs.dart'; // Import GraduateJobs
import 'undergraduate_jobs.dart'; // Import UndergraduateJobs
import 'available_for_anyone_jobs.dart'; // Import AvailableForAnyoneJobs
import 'user_applications_status.dart';
import 'messages.dart';
import 'userCommunity.dart';
import 'job_search_delegate.dart';

class HomePage extends StatefulWidget {
  final User? user;

  HomePage({this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0; // 0 for Graduate, 1 for Undergraduate, 2 for Available to Anyone

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        elevation: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('Applicants').doc(widget.user?.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('User');
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            String photoUrl = userData['photoUrl'] ?? '';

            return Row(
              children: [
                if (photoUrl.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                SizedBox(width: 10),
                Text(
                  'Hello, $fullName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      drawer: MenuDrawer(user: widget.user!), // Menu drawer
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Search Bar
            GestureDetector(
              onTap: () async {
                String category = _selectedTab == 0
                    ? 'Graduate'
                    : _selectedTab == 1
                    ? 'Undergraduate'
                    : 'Available to Anyone';
                showSearch(
                  context: context,
                  delegate: JobSearchDelegate(category: category),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search job, company etc...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Recommendation Section
            Text(
              'Recommendation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: RecommendationWidget(), // Use the RecommendationWidget
            ),
            SizedBox(height: 30),

            // Available Jobs Section
            Text(
              'Available Jobs In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                _buildCategoryTab("Graduate", _selectedTab == 0, () {
                  setState(() {
                    _selectedTab = 0;
                  });
                }),
                SizedBox(width: 20),
                _buildCategoryTab("Undergraduate", _selectedTab == 1, () {
                  setState(() {
                    _selectedTab = 1;
                  });
                }),
                SizedBox(width: 20),
                _buildCategoryTab("Available to Anyone", _selectedTab == 2, () {
                  setState(() {
                    _selectedTab = 2;
                  });
                }),
              ],
            ),
            SizedBox(height: 10),

            // Available Jobs List
            Expanded(
              child: _selectedTab == 0
                  ? GraduateJobs() // Show Graduate jobs
                  : _selectedTab == 1
                  ? UndergraduateJobs() // Show Undergraduate jobs
                  : AvailableForAnyoneJobs(), // Show Available to Anyone jobs
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.person),
            label: 'Community',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserApplicationsStatusPage(user: widget.user!),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesPage(user: widget.user!),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserCommunityPage(user: widget.user!),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoryTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}
