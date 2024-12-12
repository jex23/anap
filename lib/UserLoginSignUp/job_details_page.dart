import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'application_form_page.dart';

class JobDetailsPage extends StatelessWidget {
  final String jobTitle;
  final String company;
  final String employerId;
  final String address;
  final String salaryRange;
  final String salaryPaymentStyle;
  final String expiry;
  final String yearExperience;
  final String aboutRole;
  final List<dynamic> skills;
  final List<dynamic> requirements;
  final String status;
  final String category;
  final String jobType;
  final String jobSchedule;
  final String companyLogoUrl;

  JobDetailsPage({
    required this.jobTitle,
    required this.company,
    required this.employerId,
    required this.address,
    required this.salaryRange,
    required this.salaryPaymentStyle,
    required this.expiry,
    required this.yearExperience,
    required this.aboutRole,
    required this.skills,
    required this.requirements,
    required this.status,
    required this.category,
    required this.jobType,
    required this.jobSchedule,
    required this.companyLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Details"),
        centerTitle: true,
        backgroundColor: Colors.red[300],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo and Info Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        companyLogoUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Experience, Job Type, Level
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTag('${yearExperience} years', 'Experience'),
                    _buildTag(jobType, 'Job Type'),
                    _buildTag('Graduate', 'Level'),
                  ],
                ),
                SizedBox(height: 16),

                // Payment Style and Expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTag(salaryPaymentStyle, 'Payment Style'),
                    _buildTag(expiry, 'Expiry'),
                  ],
                ),
                SizedBox(height: 16),

                // Requirements and Skills Section
                _buildSectionTitle('Requirements'),
                requirements.isEmpty
                    ? Text('No requirements available')
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: requirements.map((req) => _buildDotList(req)).toList(),
                ),
                SizedBox(height: 16),

                _buildSectionTitle('Skills Needed'),
                skills.isEmpty
                    ? Text('No skills specified')
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: skills.map((skill) => _buildDotList(skill)).toList(),
                ),
                SizedBox(height: 16),

                // Salary and About Role
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      salaryRange,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Text(
                      DateTime.now().toString(), // Replace with actual date
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  aboutRole,
                  style: TextStyle(color: Colors.grey[600]),
                ),

                // Apply Button
                SizedBox(height: 20),
                Center(
                  child: Container(
                    width: double.infinity, // Expands to fill the available width
                    child: ElevatedButton(
                      onPressed: () async {
                        // Get the current user
                        User? user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationFormPage(
                                user: user,
                                jobTitle: jobTitle,
                                company: company,
                                employerId: employerId,
                                companyLogoUrl: companyLogoUrl,
                              ), // Pass the user object
                            ),
                          );
                        } else {
                          // Handle case where user is not logged in
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please log in to apply.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Apply Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildTag(String text, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildDotList(String text) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: Colors.redAccent),
        SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
