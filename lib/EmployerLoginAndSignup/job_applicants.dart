  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'application_detail.dart';
  import 'employerchat.dart';
  import 'employerHomepage.dart';
  import 'Employer_messages.dart';
  import 'employer_community.dart';
  import 'package:marquee/marquee.dart';
  import 'search_Applicants.dart';
  class JobApplicants extends StatelessWidget {
    final User? user;

    JobApplicants({this.user});

    Stream<QuerySnapshot> _fetchJobApplicants(String status) {
      return FirebaseFirestore.instance
          .collection('Job_Applicants')
          .where('employerId', isEqualTo: user!.uid)
          .where('applicationStatus', isEqualTo: status)
          .snapshots();
    }

    Future<Map<String, dynamic>?> _fetchApplicantDetails(String applicantsId) async {
      try {
        DocumentSnapshot applicantDoc = await FirebaseFirestore.instance
            .collection('Applicants')
            .doc(applicantsId)
            .get();

        if (!applicantDoc.exists) {
          return null; // Return null if the document does not exist
        }

        Map<String, dynamic>? applicantData = applicantDoc.data() as Map<String, dynamic>?;

        if (applicantData != null) {
          // Ensure 'status' field exists and default to 'Unemployed' if missing
          applicantData['status'] = applicantData['status'] ?? 'Unemployed';
        }

        return applicantData;
      } catch (e) {
        print('Error fetching applicant details: $e');
        return null;
      }
    }


    @override
    Widget build(BuildContext context) {
      return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red[300],
            elevation: 0,
            title: FutureBuilder<Map<String, dynamic>>(
              future: FirebaseFirestore.instance
                  .collection('Employer')
                  .doc(user!.uid)
                  .get()
                  .then((doc) => doc.data() as Map<String, dynamic>),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(color: Colors.white);
                }
                if (!snapshot.hasData) {
                  return Text("Hello, Employer");
                }
                var userData = snapshot.data!;
                String fullName = '${userData['firstName']} ${userData['lastName']}';
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userData['photoUrl'] ?? 'https://via.placeholder.com/150'),
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
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchApplicants(user: user)),
                  );
                },
              ),
            ],
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Container(
                    height: 20, // Adjust height to fit text
                    child: Marquee(
                      text: 'Under Review',
                      style: TextStyle(fontSize: 16),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 20.0,
                      velocity: 50.0,
                      pauseAfterRound: Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration: Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                ),
                Tab(text: 'Hired'),
                Tab(text: 'Declined'),
                Tab(text: 'Archived'),
              ],
            ),
          ),


          body: TabBarView(
            children: [

              _buildApplicantList(context, 'Under Review'),
              _buildApplicantList(context, 'Hired'),
              _buildApplicantList(context, 'Declined'),
              _buildApplicantList(context, 'Archived'),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            selectedItemColor: Colors.red[600],
            unselectedItemColor: Colors.grey[600],
            onTap: (index) {
              if (index == 0) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => EmployerHomepage(user: user!)));
              } else if (index == 2) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => EmployerMessages(user: user!)));
              } else if (index == 3) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => EmployerCommunity(user: user!)));
              }
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
        ),
      );
    }

    Widget _buildApplicantList(BuildContext context, String status) {
      return StreamBuilder<QuerySnapshot>(
        stream: _fetchJobApplicants(status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No applicants found for $status.'));
          }
          var applicants = snapshot.data!.docs;
          return ListView.builder(
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              var jobApplicantData = applicants[index].data() as Map<String, dynamic>;
              String applicantsId = jobApplicantData['applicantsId'];
              String docId = applicants[index].id;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Applicants')
                    .doc(applicantsId)
                    .snapshots(),
                builder: (context, applicantSnapshot) {
                  if (applicantSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!applicantSnapshot.hasData || !applicantSnapshot.data!.exists) {
                    return ListTile(title: Text('Applicant details not available.'));
                  }

                  var applicantData = applicantSnapshot.data!.data() as Map<String, dynamic>;
                  String applicantStatus = applicantData['status'] ?? 'Unemployed';

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              applicantData['photoUrl'] ?? 'https://via.placeholder.com/150',
                            ),
                            radius: 30,
                          ),
                          title: Text(jobApplicantData['name'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Job Title: ${jobApplicantData['jobTitle'] ?? 'Unknown'}'),
                              Text('Company: ${jobApplicantData['company'] ?? 'Unknown'}'),
                              if (applicantStatus == 'Hired') // Show only if Hired
                                Text('Hired by: ${applicantData['hiringCompany'] ?? 'Unknown'}'),
                              Row(
                                children: [
                                  Icon(
                                    applicantStatus == 'Hired' ? Icons.flag : Icons.outlined_flag,
                                    color: applicantStatus == 'Hired' ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '$applicantStatus',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.message),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployerChatPage(
                                    user: user!,
                                    applicantsId: applicantsId,
                                    jobTitle: jobApplicantData['jobTitle'] ?? 'Unknown',
                                    company: jobApplicantData['company'] ?? 'Unknown',
                                    companyLogoUrl: jobApplicantData['companyLogoUrl'] ?? '',
                                    applicantFullName: jobApplicantData['name'] ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplicationDetail(
                                  applicantsId: applicantsId,
                                  docId: docId,
                                ),
                              ),
                            );
                          },
                        ),
                        if (status == 'Hired') // Add "Unemploy" button for Hired tab only
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showConfirmationDialog(context, applicantsId, docId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Unemploy',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 20),

                            ],
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }

    void _showConfirmationDialog(BuildContext context, String applicantsId, String docId) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Unemploy'),
            content: Text('Do you want to unemploy this applicant?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(
                  'No',
                  style: TextStyle(color: Colors.black), // Updated text color
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _updateApplicantStatusToUnemployed(context, applicantsId, docId);
                },
                child: Text(
                  'Yes',
                  style: TextStyle(color: Colors.black), // Updated text color
                ),
              ),
            ],
          );
        },
      );
    }


    void _updateApplicantStatusToUnemployed(BuildContext context, String applicantsId, String docId) async {
      try {
        await FirebaseFirestore.instance
            .collection('Applicants')
            .doc(applicantsId)
            .update({'status': 'Unemployed'});

        await FirebaseFirestore.instance
            .collection('Job_Applicants')
            .doc(docId)
            .update({'applicationStatus': 'Archived'});


        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Applicant status updated to Unemployed.'),
          backgroundColor: Colors.red[600],
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red[600],
        ));
      }
    }
  }
