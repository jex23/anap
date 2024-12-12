import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:marquee/marquee.dart';
import 'employerchat.dart';

class ApplicationDetail extends StatelessWidget {
  final String applicantsId;
  final String docId;

  ApplicationDetail({required this.applicantsId, required this.docId});

  Stream<DocumentSnapshot> _getJobApplicationStream() {
    return FirebaseFirestore.instance
        .collection('Job_Applicants')
        .doc(docId)
        .snapshots();
  }

  Future<Map<String, dynamic>?> _fetchApplicantDetails() async {
    DocumentSnapshot applicantDoc = await FirebaseFirestore.instance
        .collection('Applicants')
        .doc(applicantsId)
        .get();
    return applicantDoc.data() as Map<String, dynamic>?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Application Details'),
        backgroundColor: Colors.red[300],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _getJobApplicationStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading application details'));
          }

          var jobApplicationData = snapshot.data!.data() as Map<String, dynamic>;
          String? resumeLink = jobApplicationData['resumeLink'];
          String applicationStatus = jobApplicationData['applicationStatus'] ?? 'Unknown';

          return FutureBuilder<Map<String, dynamic>?>(
            future: _fetchApplicantDetails(),
            builder: (context, applicantSnapshot) {
              if (applicantSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (applicantSnapshot.hasError || !applicantSnapshot.hasData) {
                return Center(child: Text('Error loading applicant details'));
              }

              var applicantData = applicantSnapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileCard(applicantData, jobApplicationData, context, applicationStatus),
                    SizedBox(height: 16),
                    _buildCoverLetterCard(jobApplicationData['coverLetter']),
                    SizedBox(height: 16),
                    if (resumeLink != null)
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: SfPdfViewer.network(resumeLink),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No resume available', style: TextStyle(fontSize: 16)),
                      ),
                    SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployerChatPage(
                user: FirebaseAuth.instance.currentUser!,
                applicantsId: applicantsId,
                jobTitle: 'Job Title Placeholder',
                company: 'Company Placeholder',
                companyLogoUrl: 'https://via.placeholder.com/150',
                applicantFullName: 'Applicant Name Placeholder',
              ),
            ),
          );
        },
        child: Icon(Icons.message, color: Colors.white),
        backgroundColor: Colors.red[300],
      ),
    );
  }

  Widget _buildProfileCard(
      Map<String, dynamic> applicantData,
      Map<String, dynamic> jobApplicationData,
      BuildContext context,
      String applicationStatus,
      ) {
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                      applicantData['photoUrl'] ?? 'https://via.placeholder.com/150'),
                  radius: 40,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobApplicationData['name'] ?? 'No Name',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, applicantData['address'] ?? 'Unknown'),
                      _buildInfoRow(Icons.cake, 'Age: ${applicantData['age'] ?? 'Unknown'}'),
                      _buildInfoRow(Icons.male, 'Gender: ${applicantData['gender'] ?? 'Unknown'}'),
                      _buildInfoRow(Icons.email, applicantData['email'] ?? 'Unknown'),
                      _buildInfoRow(Icons.phone, applicantData['phoneNumber'] ?? 'Unknown'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Job Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[600]),
            ),
            SizedBox(height: 8),
            _buildInfoRow(Icons.work, 'Job Title: ${jobApplicationData['jobTitle'] ?? 'Unknown'}'),
            _buildInfoRow(Icons.business, 'Company: ${jobApplicationData['company'] ?? 'Unknown'}'),
            _buildInfoRow(Icons.check_circle, 'Status: $applicationStatus'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(context, 'Hire', () {
                  _updateApplicationStatus(
                    context,
                    docId,
                    applicantsId,
                    'Hired',
                    jobApplicationData['company'] ?? 'Unknown Company',
                  );
                }),
                _buildMarqueeButton(context, 'Under Review', () {
                  _updateJobApplicantsOnly(context, docId, 'Under Review');
                }),
                _buildActionButton(context, 'Decline', () {
                  _updateJobApplicantsOnly(context, docId, 'Declined');
                }),
                _buildActionButton(context, 'Archive', () {
                  _updateJobApplicantsOnly(context, docId, 'Archived');
                }),
              ],
            ),




          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(

      width: 70, // Ensures consistent button size
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.white), // Same font size for all buttons
        ),
      ),
    );
  }
  Widget _buildMarqueeButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: 100, // Consistent width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: SizedBox(
          height: 23, // Consistent height for marquee text
          child: Marquee(
            text: text,
            style: TextStyle(fontSize: 16, color: Colors.white), // Same font size as others
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 20.0,
            velocity: 30.0,
            pauseAfterRound: Duration(seconds: 1),
          ),
        ),
      ),
    );
  }

  void _updateJobApplicantsOnly(BuildContext context, String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Job_Applicants')
          .doc(docId)
          .update({'applicationStatus': status});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Application status updated to $status'),
        backgroundColor: Colors.red[600],
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating status: $e'),
        backgroundColor: Colors.red[600],
      ));
    }
  }

  Widget _buildInfoRow(IconData icon, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[600], size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(info, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildCoverLetterCard(String? coverLetter) {
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Cover Letter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[600]),
              ),
            ),
            SizedBox(height: 8),
            Text(
              coverLetter ?? 'No Cover Letter Provided',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _updateApplicationStatus(
      BuildContext context,
      String docId,
      String applicantsId,
      String status,
      String company,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('Job_Applicants')
          .doc(docId)
          .update({'applicationStatus': status});

      Map<String, dynamic> updateData = {'status': status};
      if (status == 'Hired') {
        updateData['hiringCompany'] = company;
      }
      await FirebaseFirestore.instance
          .collection('Applicants')
          .doc(applicantsId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Application status updated to $status'),
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
