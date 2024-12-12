import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'available_for_anyone_apply_now_form.dart'; // Import the apply form

class AvailableForAnyoneJobDetails extends StatelessWidget {
  final Map<String, dynamic> job;

  AvailableForAnyoneJobDetails({required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        title: Text(
          'Job Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Company logo and job details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                job['companyLogoUrl'] != null
                    ? Image.network(
                  job['companyLogoUrl'],
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 60,
                  width: 60,
                  color: Colors.grey[200],
                  child: Center(child: Text('No Image')),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['company'] ?? 'No Company',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        job['jobTitle'] ?? 'No Job Title',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job['address'] ?? 'No address',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.bookmark_border, color: Colors.red),
              ],
            ),
            SizedBox(height: 16),

            // Experience, Job Type, Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCard(
                  'Experience',
                  job['yearExperience'] != null
                      ? '${job['yearExperience']} ${job['yearExperience'] == 1 ? 'year' : 'years'}'
                      : '1-2 years',
                ),
                _infoCard('Job Type', job['jobType'] ?? 'Fulltime'),
                _infoCard('Level', job['status'] ?? 'Entry Level'),
              ],
            ),
            SizedBox(height: 16),

            // Payment Style and Expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCard('Payment Style', job['salaryPaymentStyle'] ?? 'Unknown'),
                _infoCard('Expiry', job['expiry'] ?? 'No Expiry Date'),
              ],
            ),
            SizedBox(height: 16),

            // Requirements Section
            _sectionHeader('Requirements'),
            _requirementsList(job['requirements']),
            SizedBox(height: 16),

            // Skills Needed Section
            _sectionHeader('Skills Needed'),
            _skillsList(job['skills']),
            SizedBox(height: 16),

            // Salary and Date Posted
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job['salaryRange'] ?? '123k/year',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDate(job['postedAt']) ?? '18 April 2023',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),

            Text(
              job['aboutRole'] ?? 'No description available',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),

            // Apply Now Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AvailableForAnyoneApplyNowForm(
                      job: job,
                      user: null, // Add the current user if applicable
                      employerId: job['employerId'] ?? '', // Ensure employerId is available
                    ),
                  ),
                );
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
          ],
        ),
      ),
    );
  }

  // Widget for info cards (Experience, Job Type, Level)
  Widget _infoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Widget for section header
  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // Widget for requirements list
  Widget _requirementsList(dynamic requirements) {
    if (requirements is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: requirements
            .map<Widget>((req) => ListTile(
          leading: Icon(Icons.circle, color: Colors.red, size: 8),
          title: Text(req, style: TextStyle(fontSize: 14)),
        ))
            .toList(),
      );
    } else if (requirements is String && requirements.isNotEmpty) {
      return ListTile(
        leading: Icon(Icons.circle, color: Colors.red, size: 8),
        title: Text(requirements, style: TextStyle(fontSize: 14)),
      );
    } else {
      return Text('No requirements available');
    }
  }

  // Widget for skills list
  Widget _skillsList(dynamic skills) {
    if (skills is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: skills
            .map<Widget>((skill) => ListTile(
          leading: Icon(Icons.circle, color: Colors.red, size: 8),
          title: Text(skill, style: TextStyle(fontSize: 14)),
        ))
            .toList(),
      );
    } else if (skills is String && skills.isNotEmpty) {
      return ListTile(
        leading: Icon(Icons.circle, color: Colors.red, size: 8),
        title: Text(skills, style: TextStyle(fontSize: 14)),
      );
    } else {
      return Text('No skills required');
    }
  }

  // Helper function to format date fields
  String _formatDate(dynamic field) {
    if (field == null) return 'N/A';
    if (field is Timestamp) {
      return field.toDate().toString();
    }
    return field.toString();
  }
}
