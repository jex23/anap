import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_drawer.dart'; // Import MenuDrawer if you want to keep the drawer menu
import 'userHomepage.dart';
import 'user_applications_status.dart';
import 'chat_page.dart';
import 'userCommunity.dart';

class MessagesPage extends StatefulWidget {
  final User user;

  MessagesPage({required this.user});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  Future<Map<String, dynamic>?> _fetchEmployerDetails(String employerId) async {
    try {
      var doc = await FirebaseFirestore.instance.collection('Employer').doc(employerId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching employer details: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300], // Darker red for AppBar
        elevation: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Applicants')
              .doc(widget.user.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('User');
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String fullName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim();
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
      drawer: MenuDrawer(user: widget.user),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('applicantsId', isEqualTo: widget.user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No conversations found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var conversation = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(12),
                      leading: conversation['companyLogoUrl'] != null
                          ? Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(conversation['companyLogoUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.business_center, color: Colors.grey),
                      ),
                      title: Text(
                        'Job: ${conversation['jobTitle'] ?? 'No title'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Company: ${conversation['company'] ?? 'No company'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onTap: () {
                        // Navigate to ChatPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              user: widget.user,
                              employerId: conversation['employerId'],
                              jobTitle: conversation['jobTitle'],
                              company: conversation['company'],
                              companyLogoUrl: conversation['companyLogoUrl'],
                            ),
                          ),
                        );
                      },
                    ),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchEmployerDetails(conversation['employerId']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.person, color: Colors.grey),
                                ),
                                SizedBox(width: 10),
                                Text('Loading employer details...'),
                              ],
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return SizedBox.shrink();
                        }

                        var employerData = snapshot.data!;
                        String employerName = '${employerData['firstName'] ?? ''} ${employerData['lastName'] ?? ''}';
                        String employerPhotoUrl = employerData['photoUrl'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Employer"),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (employerPhotoUrl.isNotEmpty)
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(employerPhotoUrl),
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      child: Icon(Icons.person, color: Colors.grey),
                                    ),
                                  SizedBox(width: 10),
                                  Text(employerName, style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          )
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Set the current index to 2 for Messages
        selectedItemColor: Colors.red[600], // Darker red for selected item
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white, // White background for the bottom nav
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(user: widget.user),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserApplicationsStatusPage(user: widget.user),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserCommunityPage(user: widget.user),
              ),
            );

          }
        },
      ),
    );
  }
}
