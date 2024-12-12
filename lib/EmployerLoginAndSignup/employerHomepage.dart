import 'package:flutter/material.dart';
import 'employee_menu_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_post_form.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'job_applicants.dart';
import 'Employer_messages.dart';
import 'employer_community.dart';

class EmployerHomepage extends StatelessWidget {
  final User? user;

  EmployerHomepage({this.user});

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Employer')
        .doc(user!.uid)
        .get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Stream<QuerySnapshot> _fetchJobPosts() {
    return FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('employerId', isEqualTo: user!.uid)
        .snapshots();
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
              return Center(child: Text('Error loading user data'));
            }

            var userData = snapshot.data!;
            String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            String photoUrl = userData['photoUrl'] ?? 'https://via.placeholder.com/150';


            return Row(
              children: [
                if (photoUrl.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                    radius: 20, // Adjust radius size if needed
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
      drawer: EmployeeMenuDrawer(user: user!),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading user data'));
          }

          var userData = snapshot.data!;
          String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
          String photoUrl = userData['photoUrl'] ?? 'https://via.placeholder.com/150';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Container(
                //   width: double.infinity,
                //   padding: EdgeInsets.all(16.0),
                //   color: Colors.red,
                //   child: Row(
                //     children: [
                //       CircleAvatar(
                //         radius: 30,
                //         backgroundImage: NetworkImage(photoUrl),
                //       ),
                //       SizedBox(width: 10),
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             'Hello',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 18,
                //             ),
                //           ),
                //           Text(
                //             fullName,
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 24,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.add, color: Colors.red, size: 40),
                    title: Text(
                      'Create a JOB post',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text('Your Next Hire is Just a Post Away!'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobPostForm(user: user!),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchJobPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return Center(child: Text('Error loading job posts'));
                      }

                      var jobPosts = snapshot.data!.docs;

                      if (jobPosts.isEmpty) {
                        return Center(child: Text('No job posts available'));
                      }

                      return ListView.builder(
                        itemCount: jobPosts.length,
                        itemBuilder: (context, index) {
                          var jobData = jobPosts[index].data() as Map<String, dynamic>;
                          String jobTitle = jobData['jobTitle'] ?? '';
                          String company = jobData['company'] ?? '';
                          String salaryRange = jobData['salaryRange'] ?? '';
                          String salaryStyle = jobData['salaryPaymentStyle'] ?? '';
                          String status = jobData['status'] ?? '';
                          String jobType = jobData['jobType'] ?? '';
                          String schedule = jobData['jobSchedule'] ?? '';
                          String expiry = jobData['expiry'] ?? '';
                          String logoUrl = jobData['companyLogoUrl'] ?? 'https://via.placeholder.com/150';

                          return ExpandableJobCard(
                            jobTitle: jobTitle,
                            company: company,
                            salaryRange: salaryRange,
                            salaryStyle: salaryStyle,
                            status: status,
                            jobType: jobType,
                            schedule: schedule,
                            expiry: expiry,
                            address: jobData['address'] ?? '',
                            yearExperience: jobData['yearExperience'] ?? '',
                            skills: jobData['skills'] ?? '',
                            requirements: jobData['requirements'] ?? '',
                            aboutRole: jobData['aboutRole'] ?? '',
                            category: jobData['category'] ?? '',
                            postedAt: jobData['postedAt']?.toDate() ?? DateTime.now(),
                            logoUrl: logoUrl,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if(index == 1){

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobApplicants(user: user!),
              ),
            );
          }
          else if(index == 2){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobPostForm(user: user!),
              ),
            );
          }
          else if (index == 3) { // Add Job Post
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployerMessages(user: user!),
              ),
            );
          }else if (index == 4) { // Add Job Post
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployerCommunity(user: user!),
              ),
            );
          }
          // Handle other taps if needed
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
            icon: Icon(Icons.add_circle, color: Colors.red, size: 40),
            label: '',
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

class ExpandableJobCard extends StatefulWidget {
  final String jobTitle;
  final String company;
  final String salaryRange;
  final String salaryStyle;
  final String status;
  final String jobType;
  final String expiry;
  final String schedule;
  final String address;
  final String yearExperience;
  final String aboutRole;
  final String skills;
  final String requirements;
  final String category;
  final DateTime postedAt;
  final String logoUrl;

  ExpandableJobCard({
    required this.jobTitle,
    required this.company,
    required this.salaryRange,
    required this.salaryStyle,
    required this.status,
    required this.jobType,
    required this.expiry,
    required this.schedule,
    required this.address,
    required this.yearExperience,
    required this.aboutRole,
    required this.skills,
    required this.requirements,
    required this.category,
    required this.postedAt,
    required this.logoUrl,
  });

  @override
  _ExpandableJobCardState createState() => _ExpandableJobCardState();
}

class _ExpandableJobCardState extends State<ExpandableJobCard> {
  bool _isExpanded = false;
  late String currentExpiry; // Holds the current expiry status

  @override
  void initState() {
    super.initState();
    currentExpiry = widget.expiry; // Initialize with the existing expiry status
  }

  Future<void> _updateExpiry(String newExpiry) async {
    try {
      // Update the Firestore document with the new expiry status
      await FirebaseFirestore.instance
          .collection('EmployerJobPost')
          .where('jobTitle', isEqualTo: widget.jobTitle) // Assuming jobTitle is unique
          .where('employerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .limit(1)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.update({'expiry': newExpiry});
        }
      });

      // Update the local state
      setState(() {
        currentExpiry = newExpiry;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expiry status updated to $newExpiry')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating expiry status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDateTime = DateFormat('yyyy-MM-dd – hh:mm a').format(widget.postedAt);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                widget.logoUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(widget.jobTitle, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: currentExpiry.isNotEmpty && ['Hiring', 'Position Filled', 'On Hold', 'Closed'].contains(currentExpiry)
                      ? currentExpiry
                      : null, // Ensure value matches an item in the list
                  items: ['Hiring', 'Position Filled', 'On Hold', 'Closed']
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateExpiry(value);
                    }
                  },
                  hint: Text('Select Status'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.company),


                  ],
                ),
                Text(widget.address),
                Row(
                  children: [
                    Text('Pay: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.salaryRange, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(widget.schedule, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.status, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.jobType, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Posted at: $formattedDateTime'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Address: ${widget.address}'),
                  Text('Payment: ${widget.salaryStyle}'),
                  Text('Years of Experience: ${widget.yearExperience}'),
                  Text('Skills required: ${widget.skills}'),
                  Text('Requirements: ${widget.requirements}'),
                  Text('About the Role: ${widget.aboutRole}'),
                  Text('Category: ${widget.category}'),
                  Text('Posted at: $formattedDateTime'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

