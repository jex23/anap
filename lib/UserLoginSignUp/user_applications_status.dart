import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'menu_drawer.dart'; // Import MenuDrawer if you want to keep the drawer menu
import 'userHomepage.dart'; // Ensure correct import for HomePage
import 'chat_page.dart'; // Import the new ChatPage
import 'messages.dart';
import 'userCommunity.dart';

class UserApplicationsStatusPage extends StatefulWidget {
  final User user;

  UserApplicationsStatusPage({required this.user});

  @override
  _UserApplicationsStatusPageState createState() => _UserApplicationsStatusPageState();
}

class _UserApplicationsStatusPageState extends State<UserApplicationsStatusPage> {
  int _selectedIndex = 1; // Set the default selected index to 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(user: widget.user),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(user: widget.user),
        ),
      );
    }
    else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserCommunityPage(user: widget.user),
        ),
      );
    }
    // Handle other index cases if needed
  }


  // Format timestamp to readable date
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('MMM d, yyyy – h:mm a'); // 12-hour format with AM/PM
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        elevation: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('Applicants').doc(widget.user.uid).get(),
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
      drawer: MenuDrawer(user: widget.user), // Menu drawer
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Application Status Section
            Text(
              'Application Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),

            // Applications List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Job_Applicants')
                    .where('applicantsId', isEqualTo: widget.user.uid)
                    .orderBy('appliedAt', descending: true) // Sort by appliedAt in descending order
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No applications found.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var application = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      bool isAccepted = application['applicationStatus'] == 'Accepted';
                      String employerId = application['employerId'] ?? ''; // Extract employerId
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: application['companyLogoUrl'] != null
                              ? Container(
                            width: 50, // Set width for square
                            height: 50, // Set height for square
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle, // Ensure square shape
                              image: DecorationImage(
                                image: NetworkImage(application['companyLogoUrl']),
                                fit: BoxFit.cover, // Ensure image covers the container
                              ),
                            ),
                          )
                              : SizedBox.shrink(), // Empty widget if no logo
                          title: Text(application['jobTitle'] ?? 'No title'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(application['company'] ?? 'No company'),
                              if (application['appliedAt'] != null)
                                Text(
                                  _formatTimestamp(application['appliedAt'] as Timestamp),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              if (isAccepted)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: IconButton(
                                    icon: Icon(Icons.chat, color: Colors.red, size: 24),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                            user: widget.user,
                                            employerId: employerId,
                                            jobTitle: application['jobTitle'] ?? 'No title', // Pass jobTitle
                                            company: application['company'] ?? 'No company', // Pass company// Pass employerId
                                            companyLogoUrl: application['companyLogoUrl'] ?? 'No company', // Pass company// Pass employerId
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(application['applicationStatus'] ?? 'Status not available'),
                          onTap: () {
                            // Handle tap on the card, e.g., navigate to application details
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Set the current index
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
        onTap: _onItemTapped,
      ),
    );
  }
}
