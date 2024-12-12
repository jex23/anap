import 'package:anap/EmployerLoginAndSignup/job_applicants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'employerchat.dart'; // Import the chat screen
import 'employer_community.dart';
import 'employerHomepage.dart';

class EmployerMessages extends StatelessWidget {
  final User? user;

  EmployerMessages({this.user});

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Employer')
        .doc(user!.uid)
        .get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Stream<QuerySnapshot> _fetchConversations() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('employerId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> _fetchApplicantData(String applicantsId) async {
    DocumentSnapshot applicantDoc = await FirebaseFirestore.instance
        .collection('Applicants')
        .doc(applicantsId)
        .get();

    if (applicantDoc.exists) {
      return applicantDoc.data() as Map<String, dynamic>?;
    }
    return null;
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
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading conversations'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No messages found.'));
          }

          var conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              var conversation = conversations[index];
              var applicantsId = conversation['applicantsId'];
              var jobTitle = conversation['jobTitle'];
              var company = conversation['company'];
              var companyLogoUrl = conversation['companyLogoUrl'] ?? 'https://via.placeholder.com/150'; // Default placeholder
              var createdAt = (conversation['createdAt'] as Timestamp).toDate();

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchApplicantData(applicantsId),
                builder: (context, applicantSnapshot) {
                  if (applicantSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading applicant info...'),
                      subtitle: Text('Please wait'),
                    );
                  } else if (applicantSnapshot.hasError || !applicantSnapshot.hasData) {
                    return ListTile(
                      title: Text('Error loading applicant info'),
                      subtitle: Text('Could not fetch details for applicant'),
                    );
                  }

                  var applicantData = applicantSnapshot.data!;
                  String applicantFullName = '${applicantData['firstName'] ?? ''} ${applicantData['lastName'] ?? ''}'.trim();
                  String applicantPhotoUrl = applicantData['photoUrl'] ?? 'https://via.placeholder.com/150';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(applicantPhotoUrl),
                    ),
                    title: Text(applicantFullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job Title: $jobTitle'),
                        Text('Company: $company'),
                        Text('${DateFormat('MM/dd/yyyy, hh:mm a').format(createdAt)}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployerChatPage(
                            user: user!, // Ensure that the user object is not null
                            applicantsId: applicantsId,
                            jobTitle: jobTitle,
                            company: company,
                            companyLogoUrl: companyLogoUrl,
                            applicantFullName: applicantFullName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Set the current index for the 'Applicants' tab
        selectedItemColor: Colors.red[600], // Darker red for selected item
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => EmployerHomepage(user: user!)));
          }
          else if (index == 1){
            Navigator.push(context, MaterialPageRoute(builder: (context) => JobApplicants(user: user!)));
          }
          else if (index == 3){
            Navigator.push(context, MaterialPageRoute(builder: (context) => EmployerCommunity(user: user!)));
          }
          // Add additional navigation actions if necessary
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Applicants',
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
      ),
    );
  }
}
